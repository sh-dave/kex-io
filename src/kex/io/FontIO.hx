package kex.io;

import kex.io.AssetLog.*;
import kha.Font;

using tink.CoreApi;

class FontIO {
	var cachedAssets: Map<String, Font> = new Map();
	var loadingAssets: Map<String, Array<FutureTrigger<Outcome<Font, Error>>>> = new Map();
	var urlToScope: Map<String, Array<String>> = new Map();

	var assetsHandled = 0;

	public function new() {
	}

	public function get( scope: String, path: String, file: String ) : Promise<Font> {
		var url = CoreIOUtils.tagAsset(urlToScope, scope, path, file);
		var cached = cachedAssets.get(url);
		var f = Future.trigger();

		asset_info('queue font `$url` for scope `$scope`');

		if (cached != null) {
			asset_info('already cached font `$url`, adding scope `$scope`');
			f.trigger(Success(cached));
			return f;
		}

		var loading = loadingAssets.get(url);

		if (loading != null) {
			asset_info('already loading font `$url`, adding scope `$scope`');
			loading.push(f);
			return f;
		}

		asset_info('loading font `$url` for scope `$scope`');
		loadingAssets.set(url, [f]);

		kha.Assets.loadFontFromPath(url, function( font: Font ) {
			cachedAssets.set(url, font);
			asset_info('loaded font `$url` for scope `$scope`');
			var r = Success(font);
			var triggers = loadingAssets.get(url);

			if (triggers != null) {
				for (t in triggers) {
					t.trigger(r);
				}
			}

			loadingAssets.remove(url);
			assetsHandled += 1;
		}, function( err ) {
			asset_info('failed to load font `$url` for scope `$scope`');

			var r = Failure(new Error(Std.string(err)));

			var triggers = loadingAssets.get(url);

			if (triggers != null) {
				for (t in triggers) {
					t.trigger(r);
				}
			}

			loadingAssets.remove(url);
			assetsHandled += 1;
		});

		return f;
	}

	public function unloadScope( scope: String ) {
		for (url in urlToScope.keys()) {
			var scopes = urlToScope.get(url);

			if (scopes != null && scopes.indexOf(scope) != -1) {
				unloadSound(scope, url);
			}
		}
	}

	public function unloadSound( scope: String, url: String ) {
		asset_info('unscoping font `$url` for `$scope`');

		var scopes = urlToScope.get(url);

		if (scopes != null) {
			scopes.remove(scope);

			if (scopes.length == 0) {
				asset_info('unloading font `$url`');
				var asset = cachedAssets.get(url);

				if (asset != null) {
					asset.unload();
				}

				cachedAssets.remove(url);
			}
		}
	}
}

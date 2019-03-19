package kex.io;

import kex.io.AssetLog.*;
import kha.Image;

using tink.CoreApi;

class ImageIO {
	var cachedAssets: Map<String, Image> = new Map();
	var loadingAssets: Map<String, Array<FutureTrigger<Outcome<Image, Error>>>> = new Map();
	var urlToScope: Map<String, Array<String>> = new Map();

	var assetsHandled = 0;

	public function new() {
	}

	public function get( scope: String, path: String, file: String ) : Promise<Image> {
		var url = CoreIOUtils.tagAsset(urlToScope, scope, path, file);
		var cached = cachedAssets.get(url);
		var f = Future.trigger();

		asset_info('queue image `$url` for scope `$scope`');

		if (cached != null) {
			asset_info('already cached image `$url`, adding scope `$scope`');
			f.trigger(Success(cached));
			return f;
		}

		var loading = loadingAssets.get(url);

		if (loading != null) {
			asset_info('already loading image `$url`, adding scope `$scope`');
			loading.push(f);
			return f;
		}

		asset_info('loading image `$url` for scope `$scope`');
		loadingAssets.set(url, [f]);

		var loadedUrl = url;
#if (kha_kore || kha_hl)
		loadedUrl = StringTools.replace(loadedUrl, '.png', '.k');
#end
		kha.Assets.loadImageFromPath(loadedUrl, false, function( img: Image ) {
			cachedAssets.set(url, img);
			var r = Success(img);

			asset_info('loaded image `$url` for scope `$scope`');

			var triggers = loadingAssets.get(url);

			if (triggers != null) {
				for (t in triggers) {
					t.trigger(r);
				}
			}

			loadingAssets.remove(url);
			assetsHandled += 1;
		}, function( err ) {
			var r = Failure(new Error(Std.string(err)));

			asset_info('failed to load image `$url` for scope `$scope`');

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
				unloadImage(scope, url);
			}
		}
	}

	public function unloadImage( scope: String, url: String ) {
		asset_info('unscoping image `$url` for `$scope`');

		var scopes = urlToScope.get(url);

		if (scopes != null) {
			scopes.remove(scope);

			if (scopes.length == 0) {
				asset_info('unloading image `$url`');

				var asset = cachedAssets.get(url);

				if (asset != null) {
					asset.unload();
				}

				cachedAssets.remove(url);
			}
		}
	}
}

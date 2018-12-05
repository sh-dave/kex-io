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

		kha.Assets.loadImageFromPath(url, false, function( img: Image ) {
			cachedAssets.set(url, img);
			var r = Success(img);

			for (t in loadingAssets.get(url)) {
				t.trigger(r);
			}

			loadingAssets.remove(url);
			assetsHandled += 1;
		}, function( err ) {
			var r = Failure(new Error(Std.string(err)));

			for (t in loadingAssets.get(url)) {
				t.trigger(r);
			}

			loadingAssets.remove(url);
			assetsHandled += 1;
		});

		return f;
	}

	public function unloadScope( scope: String ) {
		for (url in urlToScope.keys()) {
			var scopes = urlToScope.get(url);

			if (scopes.indexOf(scope) != -1) {
				unloadImage(scope, url);
			}
		}
	}

	public function unloadImage( scope: String, url: String ) {
		var scopes = urlToScope.get(url);

		asset_info('unscoping image `$url` for `$scope`');
		scopes.remove(scope);

		if (scopes.length == 0) {
			asset_info('unloading image `$url`');
			cachedAssets.get(url).unload();
			cachedAssets.remove(url);
		}
	}
}

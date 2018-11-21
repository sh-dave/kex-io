package kex.io;

import kex.io.AssetLog.*;
import kha.Blob;

using tink.CoreApi;

class BlobIO {
	var cachedAssets: Map<String, Blob> = new Map();
	var loadingAssets: Map<String, Array<FutureTrigger<Outcome<Blob, Error>>>> = new Map();
	var urlToScope: Map<String, Array<String>> = new Map();

	var assetsHandled = 0;

	public function new() {
	}

	public function get( scope: String, path: String, file: String ) : Promise<Blob> {
		var url = CoreIOUtils.tagAsset(urlToScope, scope, path, file);
		var cached = cachedAssets.get(url);
		var f = Future.trigger();

		asset_info('[ info] queue blob `$url` for scope `$scope`');

		if (cached != null) {
			asset_info('already cached blob `$url`, adding scope `$scope`');
			f.trigger(Success(cached));
			return f;
		}

		var loading = loadingAssets.get(url);

		if (loading != null) {
			asset_info('already loading blob `$url`, adding scope `$scope`');
			loading.push(f);
			return f;
		}

		asset_info('loading blob `$url` for scope `$scope`');
		loadingAssets.set(url, [f]);

		kha.Assets.loadBlobFromPath(url, function( blob: Blob ) {
			cachedAssets.set(url, blob);
			var r = Success(blob);

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
				unloadBlob(scope, url);
			}
		}
	}

	public function unloadBlob( scope: String, url: String ) {
		var scopes = urlToScope.get(url);

		asset_info('unscoping blob `$url` for `$scope`');
		scopes.remove(scope);

		if (scopes.length == 0) {
			asset_info('unloading blob `$url`');
			cachedAssets.get(url).unload();
			cachedAssets.remove(url);
		}
	}
}

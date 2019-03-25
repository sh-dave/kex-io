package kex.io;

import kex.io.AssetLog.*;
import kha.Blob;

using tink.CoreApi;

class BlobIO {
	var cachedAssets: Map<String, Blob> = new Map();
	var loadingAssets: Map<String, Array<FutureTrigger<Outcome<Blob, Error>>>> = new Map();
	var urlToScope: Map<String, Array<String>> = new Map();

	public function new() {
	}

	public function get( scope: String, path: String, file: String ) : Promise<Blob> {
		var url = CoreIOUtils.tagAsset(urlToScope, scope, path, file);
		var cached = cachedAssets.get(url);
		var f = Future.trigger();
		var id = '`$scope:$url`';

		asset_info('queue blob $id');

		if (cached != null) {
			asset_debug('$id is already cached');
			f.trigger(Success(cached));
			return f;
		}

		var loading = loadingAssets.get(url);

		if (loading != null) {
			asset_info('$id is already loading');
			loading.push(f);
			return f;
		}

		asset_info('loading blob $id');
		loadingAssets.set(url, [f]);

		kha.Assets.loadBlobFromPath(url, function( blob: Blob ) {
			asset_info('$id finished loading');

			var r = Success(blob);
			var triggers = loadingAssets.get(url);
			cachedAssets.set(url, blob);

			if (triggers != null) {
				for (t in triggers) {
					t.trigger(r);
				}
			}

			loadingAssets.remove(url);
		}, function( err ) {
			var errmsg = Std.string(err);
			var r = Failure(new Error(errmsg));
			var triggers = loadingAssets.get(url);

			asset_err('$id failed to load ($errmsg)');

			if (triggers != null) {
				for (t in triggers) {
					t.trigger(r);
				}
			} else {
				asset_warn('no triggers for `$scope:$url`');
			}

			loadingAssets.remove(url);
		});

		return f;
	}

	public function unloadScope( scope: String ) {
		asset_info('unloading scope `$scope`');

		for (url in urlToScope.keys()) {
			var scopes = urlToScope.get(url);

			if (scopes != null && scopes.indexOf(scope) != -1) {
				unloadBlob(scope, url);
			} else {
				asset_warn('no scope `$scope` found');
			}
		}
	}

	public function unloadBlob( scope: String, url: String ) {
		var id = '`$scope:$url`';
		asset_info('unscoping $id');

		var scopes = urlToScope.get(url);

		if (scopes != null) {
			scopes.remove(scope);

			if (scopes.length == 0) {
				asset_info('unloading blob $id');

				var asset = cachedAssets.get(url);

				if (asset != null) {
					asset.unload();
				} else {
					asset_warn('no asset $id in cache found');
				}

				cachedAssets.remove(url);
			}
		} else {
			asset_warn('no scope $id found');
		}
	}
}

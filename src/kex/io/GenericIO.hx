package kex.io;

import kex.io.AssetLog.*;

using tink.CoreApi;

class GenericIO<T> {
	var cachedAssets: Map<String, T> = new Map();
	var loadingAssets: Map<String, Array<FutureTrigger<Outcome<T, Error>>>> = new Map();
	var urlToScope: Map<String, Array<String>> = new Map();
	var unloaders: Map<String, Void -> Void> = new Map();
	var tag: String;

	function new( tag: String ) {
		this.tag = tag;
	}

	function onResolve( scope: String, path: String, file: String ) : Promise<T> { return Promise.NULL; }

	public final function get( scope: String, path: String, file: String ) : Promise<T> {
		var url = CoreIOUtils.tagAsset(urlToScope, scope, path, file);
		var cached = cachedAssets.get(url);
		var f = Future.trigger();
		var id = '`$scope:$url`';

		asset_info('queue $tag $id');

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

		asset_info('loading $tag $id');
		loadingAssets.set(url, [f]);

		var ret = Future.trigger();

		onResolve(scope, path, file)
			.handle(function( o ) switch o {
				case Success(d):
					cachedAssets.set(url, d);
					var r = Success(d);
					var triggers = loadingAssets.get(url);

					if (triggers != null) {
						for (t in triggers) {
							t.trigger(r);
						}
					}

					loadingAssets.remove(url);
					ret.trigger(r);
				case err:
					var triggers = loadingAssets.get(url);

					if (triggers != null) {
						for (t in triggers) {
							t.trigger(err);
						}
					}

					loadingAssets.remove(url);
					ret.trigger(err);
			});

		return ret;
	}

	public final function unloadScope( scope: String ) {
		asset_info('unloading scope `$scope`');

		for (url in urlToScope.keys()) {
			var scopes = urlToScope.get(url);

			if (scopes != null && scopes.indexOf(scope) != -1) {
				unload(scope, url);
			} else {
				asset_warn('no scope `$scope` found');
			}
		}
	}

	final function unload( scope: String, url: String ) {
		var id = '`$scope:$url`';
		asset_info('unscoping $id');

		var scopes = urlToScope.get(url);

		if (scopes != null) {
			scopes.remove(scope);

			if (scopes.length == 0) {
				asset_info('unloading $tag $id');

				var unloader = unloaders.get(url);

				if (unloader != null) {
					unloader();
				}

				cachedAssets.remove(url);
			}
		} else {
			asset_warn('no scope $id found');
		}
	}
}

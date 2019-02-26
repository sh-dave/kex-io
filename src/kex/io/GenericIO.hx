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

		asset_info('queue $tag `$url` for scope `$scope`');

		if (cached != null) {
			asset_info('already cached $tag `$url`, adding scope `$scope`');
			f.trigger(Success(cached));
			return f;
		}

		var loading = loadingAssets.get(url);

		if (loading != null) {
			asset_info('already loading $tag `$url`, adding scope `$scope`');
			loading.push(f);
			return f;
		}

		asset_info('loading $tag `$url` for scope `$scope`');
		loadingAssets.set(url, [f]);

		var ret = Future.trigger();

		onResolve(scope, path, file)
			.handle(function( o ) switch o {
				case Success(d):
					cachedAssets.set(url, d);
					var r = Success(d);

					for (t in loadingAssets.get(url)) {
						t.trigger(r);
					}

					loadingAssets.remove(url);
					ret.trigger(r);
				case err:
					for (t in loadingAssets.get(url)) {
						t.trigger(err);
					}

					loadingAssets.remove(url);
					ret.trigger(err);
			});

		return ret;
	}

	public final function unloadScope( scope: String ) {
		for (url in urlToScope.keys()) {
			var scopes = urlToScope.get(url);

			if (scopes.indexOf(scope) != -1) {
				unload(scope, url);
			}
		}
	}

	final function unload( scope: String, url: String ) {
		var scopes = urlToScope.get(url);

		asset_info('unscoping $tag `$url` for `$scope`');
		scopes.remove(scope);

		if (scopes.length == 0) {
			asset_info('unloading $tag `$url`');

			var unloader = unloaders.get(url);

			if (unloader != null) {
				unloader();
			}

			cachedAssets.remove(url);
		}
	}
}

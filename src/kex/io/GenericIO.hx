package kex.io;

import kex.io.AssetLog.*;

using tink.CoreApi;

class GenericIO<T> {
	final cachedAssets: Map<String, T> = new Map();
	final loadingAssets: Map<String, Array<FutureTrigger<Outcome<T, Error>>>> = new Map();
	final urlToScope: Map<String, Array<String>> = new Map();
	final unloaders: Map<String, Void -> Void> = new Map();
	final tag: String;

	function new( tag: String ) {
		this.tag = tag;
	}

	function onResolve( url: String, ?opts: { ?scope: String } ) : Promise<T> {
		return Promise.NULL;
	}

	public final function get( url: String, ?opts: { ?scope: String } ) : Promise<T> {
		final scope = field(opts, 'scope', '*');
		CoreIOUtils.tagAsset(urlToScope, scope, url);
		final cached = cachedAssets.get(url);
		final f = Future.trigger();
		final id = '`$scope:$url`';

		asset_info('queue $tag $id');

		if (cached != null) {
			asset_debug('$id is already cached');
			f.trigger(Success(cached));
			return f;
		}

		final loading = loadingAssets.get(url);

		if (loading != null) {
			asset_info('$id is already loading');
			loading.push(f);
			return f;
		}

		asset_info('loading $tag $id');
		loadingAssets.set(url, [f]);

		final ret = Future.trigger();

		onResolve(url, opts) // TODO (DK) or scope?
			.handle(function( o ) switch o {
				case Success(d):
					cachedAssets.set(url, d);
					final r = Success(d);
					final triggers = loadingAssets.get(url);

					if (triggers != null) {
						for (t in triggers) {
							t.trigger(r);
						}
					}

					loadingAssets.remove(url);
					ret.trigger(r);
				case err:
					final triggers = loadingAssets.get(url);

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
			final scopes = urlToScope.get(url);

			if (scopes != null && scopes.indexOf(scope) != -1) {
				unload(scope, url);
			} else {
				asset_warn('no scope `$scope` found');
			}
		}
	}

	final function unload( scope: String, url: String ) {
		final id = '`$scope:$url`';
		asset_info('unscoping $id');

		final scopes = urlToScope.get(url);

		if (scopes != null) {
			scopes.remove(scope);

			if (scopes.length == 0) {
				asset_info('unloading $tag $id');

				final unloader = unloaders.get(url);

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

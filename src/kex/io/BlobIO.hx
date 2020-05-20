package kex.io;

import kha.Blob;

class BlobIO {
	final cachedAssets: Map<String, Blob> = new Map();
	final loadingAssets: Map<String, Array<FutureTrigger<Outcome<Blob, Error>>>> = new Map();
	final urlToScope: Map<String, Array<String>> = new Map();
	final queue: Array<{ id: String, url: String, scope: String }> = [];
	var isLoading = false;

	public final stats = {
		all: 0,
		ready: 0,
		failed: 0,
	}

	public function new() {
	}

	public function get( url: String, ?opts: { ?scope: String } ) : Promise<Blob> {
		final scope = field(opts, 'scope', '*');
		CoreIOUtils.tagAsset(urlToScope, scope, url);
		final cached = cachedAssets.get(url);
		final f = Future.trigger();
		final id = '`$scope:$url`';

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

		asset_info('queuing blob $id');
		loadingAssets.set(url, [f]);
		stats.all += 1;

		queue.push({ id: id, url: url, scope: scope });

		if (!isLoading) {
			triggerNext();
		}

		return f;
	}

	function loadImpl( data: { id: String, url: String, scope: String } ) {
		isLoading = true;
		final id = data.id;
		final url = data.url;
		final scope = data.scope;

		kha.Assets.loadBlobFromPath(url, function( blob: Blob ) {
			asset_info('$id finished loading');

			final r = Success(blob);
			final triggers = loadingAssets.get(url);
			cachedAssets.set(url, blob);

			if (triggers != null) {
				for (t in triggers) {
					t.trigger(r);
				}
			}

			loadingAssets.remove(url);
			stats.ready += 1;
			isLoading = false;
			triggerNext();
		}, function( err ) {
			final errmsg = Std.string(err);
			final r = Failure(new Error(errmsg));
			final triggers = loadingAssets.get(url);

			asset_err('$id failed to load ($errmsg)');

			if (triggers != null) {
				for (t in triggers) {
					t.trigger(r);
				}
			} else {
				asset_warn('no triggers for `$scope:$url`');
			}

			loadingAssets.remove(url);
			stats.failed += 1;
			isLoading = false;
			triggerNext();
		});
	}

	function triggerNext() {
		if (queue.length > 0) {
			final next = queue.shift();
			loadImpl(next);
		}
	}

	public function getCached( url: String )
		return cachedAssets.get(url);

	public function unloadScope( scope: String ) {
		asset_info('unloading scope `$scope`');

		for (url in urlToScope.keys()) {
			final scopes = urlToScope.get(url);

			if (scopes != null && scopes.indexOf(scope) != -1) {
				unloadBlob(scope, url);
			} else {
				asset_warn('no scope `$scope` found');
			}
		}
	}

	public function unloadBlob( scope: String, url: String ) {
		final id = '`$scope:$url`';
		asset_info('unscoping $id');

		final scopes = urlToScope.get(url);

		if (scopes != null) {
			scopes.remove(scope);

			if (scopes.length == 0) {
				asset_info('unloading blob $id');

				final asset = cachedAssets.get(url);

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

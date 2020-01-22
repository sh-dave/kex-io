package kex.io;

import kha.Image;

class ImageIO {
	final cachedAssets: Map<String, Image> = new Map();
	final loadingAssets: Map<String, Array<FutureTrigger<Outcome<Image, Error>>>> = new Map();
	final urlToScope: Map<String, Array<String>> = new Map();

	public final stats = {
		all: 0,
		ready: 0,
		failed: 0,
	}

	public function new() {
	}

	public function get( url: String, ?opts: { ?scope: String } ) : Promise<Image> {
		final scope = field(opts, 'scope', '*');
		CoreIOUtils.tagAsset(urlToScope, scope, url);
		final cached = cachedAssets.get(url);
		final f = Future.trigger();

		asset_info('queue image `$url` for scope `$scope`');

		if (cached != null) {
			asset_info('already cached image `$url`, adding scope `$scope`');
			f.trigger(Success(cached));
			return f;
		}

		final loading = loadingAssets.get(url);

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
		stats.all += 1;

		kha.Assets.loadImageFromPath(loadedUrl, false, function( img: Image ) {
			cachedAssets.set(url, img);
			var r = Success(img);

			asset_info('loaded image `$url` for scope `$scope`');

			final triggers = loadingAssets.get(url);

			if (triggers != null) {
				for (t in triggers) {
					t.trigger(r);
				}
			}

			loadingAssets.remove(url);
			stats.ready += 1;
		}, function( err ) {
			final r = Failure(new Error(Std.string(err)));

			asset_info('failed to load image `$url` for scope `$scope`');

			final triggers = loadingAssets.get(url);

			if (triggers != null) {
				for (t in triggers) {
					t.trigger(r);
				}
			}

			loadingAssets.remove(url);
			stats.failed += 1;
		});

		return f;
	}

	public function getCached( url: String )
		return cachedAssets.get(url);

	public function unloadScope( scope: String ) {
		for (url in urlToScope.keys()) {
			final scopes = urlToScope.get(url);

			if (scopes != null && scopes.indexOf(scope) != -1) {
				unloadImage(scope, url);
			}
		}
	}

	public function unloadImage( scope: String, url: String ) {
		asset_info('unscoping image `$url` for `$scope`');

		final scopes = urlToScope.get(url);

		if (scopes != null) {
			scopes.remove(scope);

			if (scopes.length == 0) {
				asset_info('unloading image `$url`');

				final asset = cachedAssets.get(url);

				if (asset != null) {
					asset.unload();
				}

				cachedAssets.remove(url);
			}
		}
	}
}

package kex.io;

import kex.io.AssetLog.*;
import kha.Font;

using tink.CoreApi;

class FontIO {
	final cachedAssets: Map<String, Font> = new Map();
	final loadingAssets: Map<String, Array<FutureTrigger<Outcome<Font, Error>>>> = new Map();
	final urlToScope: Map<String, Array<String>> = new Map();

	public final stats = {
		all: 0,
		ready: 0,
		failed: 0,
	}

	public function new() {
	}

	public function get( url: String, ?opts: { ?scope: String } ) : Promise<Font> {
		final scope = field(opts, 'scope', '*');
		CoreIOUtils.tagAsset(urlToScope, scope, url);
		final cached = cachedAssets.get(url);
		final f = Future.trigger();

		asset_info('queue font `$url` for scope `$scope`');

		if (cached != null) {
			asset_info('already cached font `$url`, adding scope `$scope`');
			f.trigger(Success(cached));
			return f;
		}

		final loading = loadingAssets.get(url);

		if (loading != null) {
			asset_info('already loading font `$url`, adding scope `$scope`');
			loading.push(f);
			return f;
		}

		asset_info('loading font `$url` for scope `$scope`');
		loadingAssets.set(url, [f]);
		stats.all += 1;

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
			stats.ready += 1;
		}, function( err ) {
			asset_info('failed to load font `$url` for scope `$scope`');

			final r = Failure(new Error(Std.string(err)));
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

	public function unloadScope( scope: String ) {
		for (url in urlToScope.keys()) {
			final scopes = urlToScope.get(url);

			if (scopes != null && scopes.indexOf(scope) != -1) {
				unloadSound(scope, url);
			}
		}
	}

	public function unloadSound( scope: String, url: String ) {
		asset_info('unscoping font `$url` for `$scope`');

		final scopes = urlToScope.get(url);

		if (scopes != null) {
			scopes.remove(scope);

			if (scopes.length == 0) {
				asset_info('unloading font `$url`');
				final asset = cachedAssets.get(url);

				if (asset != null) {
					asset.unload();
				}

				cachedAssets.remove(url);
			}
		}
	}
}

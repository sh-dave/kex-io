package kex.io;

import kex.io.AssetLog.*;
import kex.io.CoreIOUtils.*;
import kha.Sound;

using tink.CoreApi;

class SoundIO {
	final cachedAssets: Map<String, Sound> = new Map();
	final loadingAssets: Map<String, Array<FutureTrigger<Outcome<Sound, Error>>>> = new Map();
	final urlToScope: Map<String, Array<String>> = new Map();

	public final stats = {
		all: 0,
		ready: 0,
		failed: 0,
	}

	public function new() {
	}

	public function get( url: String, ?opts: { ?scope: String, ?uncompress: Bool, ?formats: Array<String> } ) : Promise<Sound> {
		final scope = field(opts, 'scope', '*');
		CoreIOUtils.tagAsset(urlToScope, scope, url);
		final cached = cachedAssets.get(url);
		final f = Future.trigger();

		asset_info('queue sound `$url` for scope `$scope`');

		if (cached != null) {
			asset_info('already cached sound `$url`, adding scope `$scope`');
			f.trigger(Success(cached));
			return f;
		}

		final loading = loadingAssets.get(url);

		if (loading != null) {
			asset_info('already loading sound `$url`, adding scope `$scope`');
			loading.push(f);
			return f;
		}

		function soundok( sound: Sound ) {
			cachedAssets.set(url, sound);
			final r = Success(sound);

			asset_info('loaded sound `$url` for scope `$scope`');

			for (t in loadingAssets.get(url)) {
				t.trigger(r);
			}

			loadingAssets.remove(url);
			stats.ready += 1;
		}

		asset_info('loading sound `$url` for scope `$scope`');
		loadingAssets.set(url, [f]);
		stats.all += 1;

		final defaultExt = kha.LoaderImpl.getSoundFormats();
		final exts = opts != null ? opts.formats != null ? opts.formats : defaultExt : defaultExt;
		final desc = { files: [for (e in exts) '${haxe.io.Path.withoutExtension(url)}.$e'] }

		@:privateAccess kha.LoaderImpl.loadSoundFromDescription(desc, function( sound: Sound ) {
			if (opts == null || opts.uncompress == null || opts.uncompress) {
				sound.uncompress(soundok.bind(sound));
			} else {
				soundok(sound);
			}
		}, function( err ) {
			final r = Failure(new Error(Std.string(err)));

			asset_err('failed to load sound `$url` for scope `$scope`');

			for (t in loadingAssets.get(url)) {
				t.trigger(r);
			}

			loadingAssets.remove(url);
			stats.failed += 1;
		});

		return f;
	}

	public function unloadScope( scope: String ) {
		for (url in urlToScope.keys()) {
			final scopes = urlToScope.get(url);

			if (scopes.indexOf(scope) != -1) {
				unloadSound(scope, url);
			}
		}
	}

	public function unloadSound( scope: String, url: String ) {
		final scopes = urlToScope.get(url);

		asset_info('unscoping sound `$url` for `$scope`');
		scopes.remove(scope);

		if (scopes.length == 0) {
			asset_info('unloading sound `$url`');
			cachedAssets.get(url).unload();
			cachedAssets.remove(url);
		}
	}
}

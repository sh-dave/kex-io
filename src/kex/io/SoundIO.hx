package kex.io;

import kex.io.AssetLog.*;
import kha.Sound;

using tink.CoreApi;

class SoundIO {
	var cachedAssets: Map<String, Sound> = new Map();
	var loadingAssets: Map<String, Array<FutureTrigger<Outcome<Sound, Error>>>> = new Map();
	var urlToScope: Map<String, Array<String>> = new Map();

	var assetsHandled = 0;

	public function new() {
	}

	public function get( scope: String, path: String, file: String, ?opts: { uncompress: Bool } ) : Promise<Sound> {
		var url = CoreIOUtils.tagAsset(urlToScope, scope, path, file);
		var cached = cachedAssets.get(url);
		var f = Future.trigger();

		asset_info('queue sound `$url` for scope `$scope`');

		if (cached != null) {
			asset_info('already cached sound `$url`, adding scope `$scope`');
			f.trigger(Success(cached));
			return f;
		}

		var loading = loadingAssets.get(url);

		if (loading != null) {
			asset_info('already loading sound `$url`, adding scope `$scope`');
			loading.push(f);
			return f;
		}

		function soundok( sound: Sound ) {
			cachedAssets.set(url, sound);
			var r = Success(sound);

			asset_info('loaded sound `$url` for scope `$scope`');

			for (t in loadingAssets.get(url)) {
				t.trigger(r);
			}

			loadingAssets.remove(url);
			assetsHandled += 1;
		}

		asset_info('loading sound `$url` for scope `$scope`');
		loadingAssets.set(url, [f]);

		kha.Assets.loadSoundFromPath(url, function( sound: Sound ) {
			if (opts == null || opts.uncompress) {
				sound.uncompress(soundok.bind(sound));
			} else {
				soundok(sound);
			}
		}, function( err ) {
			var r = Failure(new Error(Std.string(err)));

			asset_info('failed to load sound `$url` for scope `$scope`');

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
				unloadSound(scope, url);
			}
		}
	}

	public function unloadSound( scope: String, url: String ) {
		var scopes = urlToScope.get(url);

		asset_info('unscoping sound `$url` for `$scope`');
		scopes.remove(scope);

		if (scopes.length == 0) {
			asset_info('unloading sound `$url`');
			cachedAssets.get(url).unload();
			cachedAssets.remove(url);
		}
	}
}

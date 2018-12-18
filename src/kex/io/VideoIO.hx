package kex.io;

import kex.io.AssetLog.*;
import kha.Video;

using tink.CoreApi;

class VideoIO {
	var cachedAssets: Map<String, Video> = new Map();
	var loadingAssets: Map<String, Array<FutureTrigger<Outcome<Video, Error>>>> = new Map();
	var urlToScope: Map<String, Array<String>> = new Map();

	var assetsHandled = 0;

	public function new() {
	}

	public function get( scope: String, path: String, file: String ) : Promise<Video> {
		var url = CoreIOUtils.tagAsset(urlToScope, scope, path, file);
		var cached = cachedAssets.get(url);
		var f = Future.trigger();

		asset_info('queue video `$url` for scope `$scope`');

		if (cached != null) {
			asset_info('already cached video `$url`, adding scope `$scope`');
			f.trigger(Success(cached));
			return f;
		}

		var loading = loadingAssets.get(url);

		if (loading != null) {
			asset_info('already loading video `$url`, adding scope `$scope`');
			loading.push(f);
			return f;
		}

		asset_info('loading video `$url` for scope `$scope`');
		loadingAssets.set(url, [f]);

		kha.Assets.loadVideoFromPath(url, function( video: Video ) {
			cachedAssets.set(url, video);
			var r = Success(video);

			asset_info('loaded video `$url` for scope `$scope`');

			for (t in loadingAssets.get(url)) {
				t.trigger(r);
			}

			loadingAssets.remove(url);
			assetsHandled += 1;
		}, function( err ) {
			var r = Failure(new Error(Std.string(err)));

			asset_info('failed to load video `$url` for scope `$scope`');

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

		asset_info('unscoping video `$url` for `$scope`');
		scopes.remove(scope);

		if (scopes.length == 0) {
			asset_info('unloading video `$url`');
			cachedAssets.get(url).unload();
			cachedAssets.remove(url);
		}
	}
}

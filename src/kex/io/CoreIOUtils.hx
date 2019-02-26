package kex.io;

class CoreIOUtils {
	public static function genUrl( path, file )
		return '$path/$file';

	public static function tagAsset( map: Map<String, Array<String>>, scope: String, path: String, file: String ) : String {
		var url = genUrl(path, file);
		var scoped = map.get(url);

		if (scoped == null) {
			map.set(url, [scope]);
		} else {
			if (scoped.indexOf(scope) == -1) {
				scoped.push(scope);
			}
		}

		return url;
	}
}

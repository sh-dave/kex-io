package kex.io;

class CoreIOUtils {
	public static function field( a: Dynamic, name: String, def: Dynamic ) : Dynamic {
		if (a == null) {
			return def;
		}

		final f = Reflect.field(a, name);
		return f != null ? f : def;
	}

	public static function tagAsset( map: Map<String, Array<String>>, scope: String, url: String ) : String {
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

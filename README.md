# kex-io [![License: Zlib](https://img.shields.io/badge/License-Zlib-green.svg)](https://opensource.org/licenses/Zlib)

Async asset handling for [Kha](https://github.com/Kode/Kha.git). The code is heavily based on [iron's Data class](https://github.com/armory3d/iron/blob/master/Sources/iron/data/Data.hx), but uses promises instead of callbacks. It also features a simple scoping (i.e. reference counting) mechanism. All assets are cached, whether already loaded or still in progress.

## dependencies

- [tink_core](https://github.com/haxetink/tink_core.git)

## optional dependencies

- [tink_core_ext](https://github.com/kevinresol/tink_core_ext.git) for  `Promises.multi()`
- [tink_await](https://github.com/haxetink/tink_await.git) if you prefer to use javascript style `@:await` instead of manually handling the promises

## usage

```haxe
using tink.CoreApi;
var blobs = new kex.io.BlobIO();
```

#### load a single file

```haxe
blobs.get('a.txt').handle(function( o ) switch o {
	case Success(blob):
		trace(blob.toString());
	case Failure(err):
});
```

#### load 2 files

```haxe
(blobs.get('foo.txt') && blobs.get('bar.txt')).handle(function( o ) switch o {
	case Success(data):
		trace(data.a.toString()); // foo
		trace(data.b.toString()); // bar
	case Failure(err);
});
```

#### load multiple files

```haxe
Promise.inParallel([
	blobs.get('a.txt'),
	blobs.get('b.txt'),
	blobs.get('c.txt'),
]).handle(function( o ) switch o {
	case Success(datas):
		for (data in datas) {
			trace(data.toString());
		}
	case Failure(err);
});
```

#### load some json

```haxe
typedef Foo = {
	final someInt: Int;
	final someString: String;
}

blobs.get('foo.json').next(function( b ) {
	var foo: Foo = tink.Json.parse(b.toString());
	return foo;
}).handle(function( o ) switch o {
	case Success(foo):
		trace(foo.someInt);
		trace(foo.someString);
	case Failure(err):
});
```

#### scopes

```haxe
Promise.inParallel([
	blobs.get('a.txt', { scope: 'scope-a' }),
	blobs.get('b.txt', { scope: 'scope-a' }),
	blobs.get('b.txt', { scope: 'scope-b' }), // uses cached b.txt
	blobs.get('c.txt', { scope: 'scope-c' }),
]).handle(function( o ) switch o {
	case Success(datas):
		blobs.unloadScope('scope-a');
		// will unload `a.txt`
		// keeps `b.txt` around, as it is also required in `scope-b`
	case Failure(err);
});
```

#### named fields (using tink_core_ext's Promises)

```haxe
Promises.multi({
	hello: blobs.get('a.txt'),
	world: blobs.get('b.txt'),
]).handle(function( o ) switch o {
	case Success(datas):
		trace(datas.hello);
		trace(datas.world);
	case Failure(err);
});
```

## logging

Use the initialization macro `--macro kex.io.AssetLog.level(X)` to enable more verbose logging (default is `errors`).
If you want to use some custom logging mechanism, define `kex_io_custom_log` to disable the provided logger, add a `kex.io.AssetLog` class somewhere in your classpath and define the 4 required macros (`asset_debug`, `asset_info`, `asset_warn`, `asset_err`).

X | name
-|-
0 | no logging code will be generated
1 | errors
2 | warnings
3 | info
4 | debug

## scoping

In case you don't supply a scope for your assets, the default `*` is used.

# kex-io

Async asset handling for [Kha](https://github.com/Kode/Kha.git). The code is heavily based on [iron's Data class](https://github.com/armory3d/iron/blob/master/Sources/iron/data/Data.hx), but uses promises instead of callbacks. It also features a simple scoping (i.e. reference counting) mechanism. All assets are cached, whether already loaded or still in progress.

## dependencies

- add [tink_core](https://github.com/haxetink/tink_core.git) to your main project's `khafile.js` as nested `addProject` call's don't quite work in khamake yet

## usage

```haxe
using tink.CoreApi;

var blobs = new kex.io.BlobIO();

// load 1
blobs.get('*', './', 'a.txt')
	.handle(function( o ) switch o {
		case Success(blob):
			trace(blob.toString());
		case Failure(err):
	});

// load 2
(blobs.get('*', './', 'a.txt') && blobs.get('*', './', 'b.txt'))
	.handle(function( o ) switch o {
		case Success(data):
			trace(data.a.toString());
			trace(data.b.toString());
		case Failure(err);
	});

// load many
Promise.inParallel([
	blobs.get('*', './', 'a.txt'),
	blobs.get('*', './', 'b.txt'),
	blobs.get('*', './', 'c.txt'),
]).handle(function( o ) switch o {
	case Success(datas):
		for (data in datas) {
			trace(data.toString());
		}
	case Failure(err);
});

// load json
typedef Foo = {
	someInt: Int,
	someString: String,
}

blobs.get('*', './', 'foo.json')
	.next(function( b ) {
		var foo: Foo = tink.Json.parse(b.toString());
		return foo;
	}).handle(function( o ) switch o {
		case Success(foo):
			trace(foo.someInt);
			trace(foo.someString);
		case Failure(err):
	});
	
// scopes
Promise.inParallel([
	blobs.get('scope-a', './', 'a.txt'),
	blobs.get('scope-a', './', 'b.txt'),
	blobs.get('scope-b', './', 'b.txt'), // won't actually load `b.txt` again, but get it from the cache
	blobs.get('scope-c', './', 'c.txt'),
]).handle(function( o ) switch o {
	case Success(datas):
		blobs.unloadScope('scope-a');
		// unloads `a.txt`
		// keeps `b.txt` around, as it is also required in `scope-b`
	case Failure(err);
});
```

# kex-io

Async asset handling for [Kha](https://github.com/Kode/Kha.git).

```haxe
using tink.CoreApi;

var blobs = new kex.io.BlobIO();

// load 1
blobs.get('a.txt')
	.handle(function( o ) switch o {
		case Success(blob):
			trace(blob.toString());
		case Failure(err):
	});

// load 2
(blobs.get('a.txt') && blobs.get('b.txt'))
	.handle(function( o ) switch o {
		case Success(data):
			trace(data.a.toString());
			trace(data.b.toString());
		case Failure(err);
	});

// load many
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

// load json
typedef Foo = {
	someInt: Int,
	someString: String,
}

blobs.get('foo.json')
	.next(function( b ) {
		var f: Foo = tink.Json.parse(b.toString());
		return f;
	}).handle(function( o ) switch o {
		case Success(json):
			trace(json.someInt);
			trace(json.someString);
		case Failure(err):
	});
```

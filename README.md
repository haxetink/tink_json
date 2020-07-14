# Tinkerbell JSON

[![Build Status](https://travis-ci.org/haxetink/tink_json.svg?branch=master)](https://travis-ci.org/haxetink/tink_json)
[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/haxetink/public)

This library provides a macro powered approach to JSON handling. It handles both JSON parsing and json writing, based on expected or known type respectively.

## Writing

For writing, `tink_json` generates a writer based on the know type, that writes all known data to the resulting String.

Consider this:

```haxe
var greeting = { hello: 'world', foo: 42 };
var limited:{ hello:String } = greeting;
trace(tink.Json.stringify(greeting));//{"hello":"world"}
```

In the above example we can see `foo` not showing up, because the type being serialized does not contain it.

## Reading

For reading, `tink_json` generates a parser based on the expected type. Note that the parser is validating while parsing.

Example:

```haxe
var o:{ foo:Int, bar:Array<{ flag:Bool }> } = tink.Json.parse('{ "foo": 4, "blub": false, "bar": [{ "flag": true }, { "flag": false, "foo": 4 }]}');
trace(o);//{ bar : [{ flag : true },{ flag : false }], foo : 4 }
```

Notice how fields not mentioned in the expected type do not show up.

## Non-JSON Haxe types

This library is able to represent types in JSON that don't directly map to JSON types, i.e. `Map` and enums.

Maps are represented as an array of key-value pairs, e.g. `['foo'=>5 , 'bar' => 3]` is represented as `[['foo', 5] ,['bar', 3]]`.

### Enums

The default representation of enums is this:

```haxe
enum Color {
  Rgb(a:Int, b:Int, c:Int);
  Hsv(hsv:{ hue:Float, saturation:Float, value:Float });//notice the single argument with name equal to the constructor
  Hsl(value:{ hue:Float, saturation:Float, lightness:Float });
  White;//no constructor
}

Rgb(0, 255, 128);
Hsv({ hue: 0, saturation: 100, value: 100 });
Hsl({ hue: 0, saturation: 100, lightness: 100 });
White;
//becomes
{ "Rgb": { "a": 0, "b": 255, "c": 128}}
{ "Hsv": { "hue": 0, "saturation": 100, "value": 100 }} //object gets "inlined" because it follows the above convention
{ "Hsl": { "value: { "hue": 0, "saturation": 100, "lightness": 100 } }}
"White"
```

This is nice in that it is a pretty readable and close to the original.

However you may want to use enums to consume 3rd party data in a typed fashion.

Imagine this json:

```js
[{
  "type": "sword",
  "damage": 100
},{
  "type": "shield",
  "armor": 50
}]
```

You can represent it like so:

```haxe
enum Item {
  @:json({ type: 'sword' }) Sword(damage:Int);
  @:json({ type: 'shield' }) Shield(armor:Int);
  @:json("junk") Junk; //<-- special case for argumentless constructors
}
```

### Dates

Dates are represented simply as floats obtained by calling `getTime()` on a `Date`.

### Bytes

Bytes are represented in their Base64 encoded form.

### Custom Abstracts

Custom abstracts that have a `from` and `to` to a type that can be JSON encoded, will be represented as such a type.

Alternatively, you can declare implicit casts `@:from` and `@:to` for `tink.json.Representation<T>` where `T` will then be used as a representation.

Example:

```haxe
import tink.json.Representation;

abstract UpperCase(String) {

  inline function new(v) this = v;

  @:to function toRepresentation():Representation<String>
    return new Representation(this);

  @:from static function ofRepresentation(rep:Representation<String>)
    return new UpperCase(rep.get());

  @:from static function ofString(s:String)
    return new UpperCase(s.toUpperCase());
}
```

Notice how strings used as JSON representation are treated differently from ordinary strings.

### Optional Fields and Nulls

By default `tink_json` will not encode an optional field if the value is `null`. In code that means:

```haxe
var o:{?a:Int} = {a: null}
tink.Json.stringify(o) == '{}'; // true
```

If you want `null` to be encoded as well, you can remove the optional notation and wrap the type with `Null`, e.g.

```haxe
var o:{a:Null<Int>} = {a: null}
tink.Json.stringify(o) == '{"a":null}'; // true
```

If you want to explicitly control when a value should be encoded or omitted, wrap the type with `haxe.ds.Option`. When the value is `None`, the field will be omitted. When the value is `Some(data)`, the field will always be encoded, even `data` is null. e.g.

```haxe
var o:{a:Option<Null<Int>>} = {a: None}
tink.Json.stringify(o) == '{}'; // true

var o:{a:Option<Null<Int>>} = {a: Some(null)}
tink.Json.stringify(o) == '{"a":null}'; // true

var o:{a:Option<Null<Int>>} = {a: Some(1)}
tink.Json.stringify(o) == '{"a":1}'; // true
```

### Custom parsers

Using `@:jsonParse` on a type, you can specify how it should be parsed. The metadata must have exactly one argument, that is either of the following:

- a function that consumes the data as it is expected to be found in the JSON document and must produce the type to be parsed.
- a class that must provide an instance method called `parse` with the same signature and also have a constructor that accepts a `tink.json.Parser.BasicParser` - which will reference the parser from which your custom parser is invoked. You can use it's `plugins` field to share state between custom parsers. See the [tink_core documentation](https://haxetink.github.io/#/tink_core) for more details on that.

Example:

```haxe
@:jsonParse(function (json) return new Car(json.speed, json.make))
class Car {
  public var speed(default, null):Int;
  public var make(default, null):String;
  public function new(speed:Int, make:String) {
    this.speed = speed;
    this.make = make;
  }
}
```

**Note**: Imports and usings have no effect on the code in `@:jsonParse`, so you must use fully qualified paths at all times.

### Custom serializers

Similarly to `@:jsonParse`, you can use `@:jsonStringify` on a type to control how it should be parsed. The metadata must have exactly on argument:

- a function that consumes the data to be serialized and produces the data that should be serialized into the final JSON document.
- a class that must provide an instance method called `prepared` with the same signature and also have a constructor that accepts a `tink.json.Writer.BasicWriter`, that again allows you to share state between custom parsers through its `plugins`.

Example:

```haxe
@:jsonStringify(function (car:Car) return { speed: car.speed, make: car.make })
class Car {
  // implementation the same as above
}
```

### Cached Values

A relatively advanced feature of tink_json is its support for caching recurrent values.

```haxe
package tink.json;

typedef Cached<T:{}> = T;
```

Using `Cached<SomeType>` instead of just `SomeType` will make tink_json cache that type, without otherwise interfering with it (because the typedef just goes away). To understand what caching really means, it's best to consider the following example. Imagine the following:

```haxe
import tink.json.*;// importing Cached, Parser and Writer

var alice:Person = { name: 'Alice' },
    bob:Person = { name: 'Bob' },
    carl:Person = { name: 'Carl' };

var daisy:Person = { name: 'Daisy', mother: alice, father: bob },
    eugene:Person = { name: 'Eugene', mother: alice, father: carl };

trace(daisy == daisy);// true - evidently
trace(daisy.mother == eugene.mother);// true

var w = new Writer<Person>(),
    p = new Parser<Person>();

var daisyClone = p.parse(w.write(daisy)),
    eugeneClone = p.parse(w.write(eugene));

trace(daisyClone != daisy);// true - evidently
trace(daisyClone.mother == eugeneClone.mother);// true - what sorcery is this?!

// let's start afresh and see
var w = new Writer<Person>();
trace(w.write(daisy));// {"name":"Daisy","father":{"name":"Bob"},"mother":{"name":"Alice"}} - nothing special ...
trace(w.write(eugene));// {"name":"Eugene","father":{"name":"Carl"},"mother":2} - oh, look alice is simply referred to by id
trace(w.write(alice));// 2 - indeed, she is
trace(w.write(daisy));// 0 - and the same is true for daisy
```

The first time a writer encounters a cachable value, it writes the full value and tracks an incremental id. On subsequent writes, it uses the same id. This happens per writer instance, so if you use a new writer for every serialization (as `tink.Json.serialize` does), then caching will be used *within the same document*, but not accross them. Parsers work equivalently: when encountering a cachable value for the first time, they assign an incremental id and wheneve they encounter an int where a cachable value may be, they use it to look up cached values (or produce an error if the value could not be found in the cache).

#### Use cases for Cached Values

1. Denormalized data: if you have data that is not normalized, such as the above "family tree", caching will provide deduplication in the serialized form and physical equality when deserializing again.

2. Circular data: This is an edge case of denormalized data, that normally results in stack overflows. Using caching, this works without problems.

3. Repetitive strings: `Cached` also works for strings, so if you have strings that come up a lot, you can use caching to reduce duplication.

4. Persistent connection: if you stream documents from a server to a client, you can make the server's writer and the client's parser be the same over the connection's life cycle. Thus, if the server sends the same object twice for whatever reason, no actual payload needs to be sent.

#### Caveats for Cached Values

1. Cached values are hard to deal with for any non-tink_json code. Perhaps an additional mode will be added to write `{"$ref":2,"name":"Alice"}` and `{"$ref":2}` respectively.
2. Writers and parsers become stateful and that's a great way to introduce bugs and memory leaks into your application. You must therefore pay very special attention to the life cycle of your writers and parsers and take care of reinstantiating them often enough to avoid filling memory with obsolete data. This simplest way to avoid problems is of course to use fresh writers/parsers for every operation, thus foregoing the benefits and risks of more long lived caches.

## Performance

Here are the benchmark results of the current state of this library:

| platform | write speedup | read speedup |
|---------:|--------------:|-------------:|
| interp   |          1.32 |         0.53 |
| neko     |          1.09 |         0.56 |
| python   |          5.8  |         0.07 |
| nodejs   |          4.75 |         0.16 |
| java     |          1.94 |         1.48 |
| cpp      |          2.86 |         0.9  |
| cs       |          8.46 |         1.37 |
| php      |          0.92 |         0.28 |

While the numbers for writing look great, reading obviously could use some more optimization. On static platforms performance can be further increased by allowing to parse/stringify class instances, as accessing fields on instances is significantly faster. Particularly on Python and JavaScript it is clear that the native functionality needs to be used, ideally using object_hook/reviver to perform on-the-fly transformation.

## Benefits

Using `tink_json` adds a lot more safety to your application. You get a validating parser for free. You get compile time errors if you try to parse or write values that cannot be represented in JSON. At the same time the range of things you can represent is expanded considerably. Also, you get full control over what gets parsed and written, meaning that you don't have to waste memory parsing parts of data you don't intend to use and also you won't have fields written that you know nothing about. If you are working with an object store such as MongoDB, then data parsed with tink_json is safe to insert into the database (in the sense that it will not be malformed) and data serialized with tink_json will not leak internal database fields, provided it is omitted in the type that is being serialized.

## Caveats

The most important thing to be aware of though is that roundtripping JSON through `tink_json` will discard all the things it does not know about. So if you want to load some JSON, modify a field and then write the JSON back, this library will cause data elimination. This may be a good way to get rid of stale data, but also an awesome way to shoot someone else (relying on the data you don't know about) in the foot. You have been warned.

This library generates quite a lot of code. The overhead is reasonable, but if you use it to parse complex data structures only to access very few values, you might find it too high. OTOH hand if you reduce the type declaration to the bits you need, only the necessary code is generated and also all the noise is discarded while parsing, resulting in better overall performance.


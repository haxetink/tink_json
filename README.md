# Tinkerbell JSON

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

var o:{ foo: Int, bar:Array<{ flag: Bool }> } = tink.Json.parse('{ "foo": 4, "blub": false, "bar": [{ "flag": true }, { "flag": false, foo: 4 }]}');
trace(o);//{ foo: 4, bar: [{ flag: true }, { flag: false }]}
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
}

Rgb(0, 255, 128);
Hsv({ hue: 0, saturation: 100, value: 100 });
Hsl({ hue: 0, saturation: 100, lightness: 100 });
//becomes
{ "Rgb": { "a": 0, "b": 255, "c": 128}}
{ "Hsv": { "hue": 0, "saturation": 100, "value": 100 }} //object gets "inlined" because it follows the above convention
{ "Hsl": { "value: { "hue": 0, "saturation": 100, "lightness": 100 } }}
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
}
```

### Dates

Dates are represented simply as floats obtained by calling `getTime()` on a `Date`.

### Bytes

Bytes are represented in their Base64 encoded form.

## Benefits

Using `tink_json` adds a lot more safety to your application. You get a validating parser for free. You get compile time errors if you try to parse or write values that cannot be represented in JSON. At the same time the range of things you can represent is expanded considerably. Also, you get full control over what gets parsed and written, meaning that you don't have to waste memory parsing parts of data you don't intend to use and also you won't have data written that 

Another benefit is that `tink_json` can perform better in some situations, particularly for writing JSON, which makes it a suitable choice for writing JSON APIs. For example on nodejs it can serialize data up to 3 times faster than the native counterpart. Sadly, it is currently slower when parsing on most platforms, partly because the underlying parser leaves much room for optimization. So there is hope yet!

## Caveats

The most important thing to be aware of though is that roundtripping JSON through `tink_json` will discard all the things it does not know about. So if you want to load some JSON, modify a field and then write the JSON back, this library will cause data elimination. This may be a good way to get rid of stale data, but also an awesome way to shoot someone else (relying on the data you don't know about) in the foot. You have been warned.

This library generates quite a lot of code. The overhead is reasonable, but if you use it to parse complex data structures only to access very few values, you might find it too high. OTOH hand if you reduce the type declaration to the bits you need, very little code is generated and also all the noise is discarded while parsing, resulting in better overall performance.
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

## Benefits

More on that later ...

## Caveats

The most important thing to be aware of though is that roundtripping JSON through `tink_json` will discard all the things it does not know about. So if you want to load some JSON, modify a field and then write the JSON back, this library will cause data elimination. This may be a good way to get rid of stale data, but also an awesome way to shoot someone else (relying on the data you don't know about) in the foot. You have been warned.

This library generates quite a lot of code. The overhead is reasonable, but if you use it to parse complex data structures only to access very few values, you might find it too high. OTOH hand if you reduce the type declaration to the bits you need, very little code is generated and also all the noise is discarded while parsing, resulting in better overall performance.
# Tinkerbell JSON

This library provides a macro powered approach to JSON handling. Currently it implements only parsing.

At compile time, it generates a parser based on the expected type that doesn't require reflection to construct the parsed values, nor does it allocate values found in the parsed JSON but not required by the expected type.

Example:
  
```haxe

var o:{ foo: Int, bar:Array<{ flag: Bool }> } = tink.Json.parse('{ "foo": 4, "blub": false, "bar": [{ "flag": true }, { "flag": false, foo: 4 }]}');
trace(o);//{ foo: 4, bar: [{ flag: true }, { flag: false }]} -- notice how fields not mentioned do not show up
```

The JSON is also validated while parsed. The approach taken by this library has a potential to be more memory efficient and possibly run faster also. That remains to be measured and optimized.
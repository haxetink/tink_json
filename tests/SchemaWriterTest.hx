package;

import tink.json.schema.Schema;
import tink.json.schema.SchemaWriter;
import tink.json.schema.JsonSchema;
import haxe.DynamicAccess;
import Types;

@:jsonStringify(function (v) return { x: v.value })
class WrappedInt {
	public var value(default, null):Int;
	public function new(value) this.value = value;
}

@:jsonStringify(v -> (cast v:Float))
abstract AsNumber(Float) {
	public inline function new(v) this = v;
}

class AltitudeWriter {
	public function new(v:tink.json.Writer.BasicWriter) {}
	public function prepare(a:Altitude) {
		return { alt: a.value };
	}
}

@:jsonStringify((_:SchemaWriterTest.AltitudeWriter))
class Altitude {
	public var value(default, null):Float;
	public function new(value) this.value = value;
}

@:asserts
class SchemaWriterTest {
	static inline var HEADER = '"$$schema":"https://json-schema.org/draft/2020-12/schema"';
	
	public function new() {}
	
	@:variant(SPrimitive(PString(null)), '{"type":"string"}')
	@:variant(SPrimitive(PString('White')), '{"type":"string","const":"White"}')
	@:variant(SPrimitive(PFloat(null)), '{"type":"number"}')
	@:variant(SPrimitive(PFloat(1.5)), '{"type":"number","const":1.5}')
	@:variant(SPrimitive(PInt(null)), '{"type":"integer"}')
	@:variant(SPrimitive(PInt(5)), '{"type":"integer","const":5}')
	@:variant(SPrimitive(PInt(null, 0)), '{"type":"integer","minimum":0}')
	@:variant(SPrimitive(PBool(null)), '{"type":"boolean"}')
	@:variant(SPrimitive(PBool(true)), '{"type":"boolean","const":true}')
	@:variant(SPrimitive(PDate), '{"type":"number","description":"Unix timestamp in milliseconds"}')
	@:variant(SPrimitive(PRegex('^[a-z]+$')), '{"type":"string","pattern":"^[a-z]+$"}')
	@:variant(SAny, '{}')
	@:variant(SConst('circle'), '{"const":"circle"}')
	@:variant(SRef('Foo'), '{"$$ref":"#/$$defs/Foo"}')
	@:variant(SNullable(SRef('Foo')), '{"oneOf":[{"$$ref":"#/$$defs/Foo"},{"type":"null"}]}')
	@:variant(SNullable(SPrimitive(PString(null))), '{"type":["string","null"]}')
	@:variant(SOneOf([SPrimitive(PString('White'))]), '{"oneOf":[{"type":"string","const":"White"}]}')
	@:variant(STuple([SPrimitive(PInt(null)),SPrimitive(PString(null))]), '{"type":"array","prefixItems":[{"type":"integer"},{"type":"string"}],"items":false,"minItems":2}')
	@:variant(SArray(SPrimitive(PString(null))), '{"type":"array","items":{"type":"string"}}')
	@:variant(SObject([{name:'foo', type:SPrimitive(PString(null)), optional:false}]), '{"type":"object","additionalProperties":false,"required":["foo"],"properties":{"foo":{"type":"string"}}}')
	@:variant(SObject([{name:'bar', type:SPrimitive(PInt(null)), optional:true}]), '{"type":"object","additionalProperties":false,"required":[],"properties":{"bar":{"type":"integer"}}}')
	@:variant(SDynamicAccess(SPrimitive(PString(null))), '{"type":"object","additionalProperties":{"type":"string"}}')
	@:variant(SEnum([0, 1, 2]), '{"enum":[0,1,2]}')
	@:variant(SEnum(['a', 'b']), '{"enum":["a","b"]}')
	public function writeType(schema:SchemaType, output:String) {
		asserts.assert(JsonSchema.writeType(schema) == output);
		return asserts.done();
	}
	
	@:variant(tink.Json.schema(String), '{"type":"string"}')
	@:variant(tink.Json.schema(Int), '{"type":"integer"}')
	@:variant(tink.Json.schema(Float), '{"type":"number"}')
	@:variant(tink.Json.schema(Date), '{"type":"number","description":"Unix timestamp in milliseconds"}')
	@:variant(tink.Json.schema(Bool), '{"type":"boolean"}')
	@:variant(tink.Json.schema(UInt), '{"type":"integer","minimum":0}')
	@:variant(tink.Json.schema(haxe.io.Bytes), '{"type":"string","pattern":"^[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789\\\\+/=]*$"}')
	@:variant(tink.Json.schema(Dynamic), '')
	@:variant(tink.Json.schema(tink.json.Value), '')
	@:variant(this.makeNullableStringSchema(), '{"type":["string","null"]}')
	@:variant(this.makeStringMapSchema(), '{"type":"array","items":{"type":"array","prefixItems":[{"type":"string"},{"type":"integer"}],"items":false,"minItems":2}}')
	@:variant(this.makeArraySchema(), '{"type":"array","items":{"type":"string"}}')
	@:variant(this.makeDynamicAccessSchema(), '{"type":"object","additionalProperties":{"type":"string"}}')
	@:variant(this.makeEnumAbstractSchema(), '{"enum":[0,1,2,3,4,5,6]}')
	@:variant(this.makePairSchema(), '{"type":"array","prefixItems":[{"type":"string"},{"type":"integer"}],"items":false,"minItems":2}')
	@:variant(this.makeEitherSchema(), '{"oneOf":[{"type":"string"},{"type":"integer"}]}')
	@:variant(this.makeAsNumberSchema(), '{"type":["number","null"]}')
	public function write(schema:Schema, body:String) {
		final expected = body == '' ? '{$HEADER}' : '{$HEADER,${body.substr(1)}';
		asserts.assert(JsonSchema.write(schema) == expected);
		return asserts.done();
	}
	
	@:variant(this.makeColorSchema(), '_SchemaWriterTest.Color', '{"oneOf":[{"type":"string","const":"White"},{"type":"object","additionalProperties":false,"required":["Hsl"],"properties":{"Hsl":{"type":"object","additionalProperties":false,"required":["value"],"properties":{"value":{"$$ref":"#/$$defs/Anon0"}}}}},{"type":"object","additionalProperties":false,"required":["Hsv"],"properties":{"Hsv":{"type":"object","additionalProperties":false,"required":["hue","saturation","value"],"properties":{"hue":{"type":"number"},"saturation":{"type":"number"},"value":{"type":"number"}}}}}]}')
	@:variant(this.makeShapeSchema(), 'SchemaWriterTest.Shape', '{"oneOf":[{"type":"string","const":"dot"},{"type":"object","additionalProperties":false,"required":["type","radius"],"properties":{"type":{"const":"circle"},"radius":{"type":"number"}}},{"type":"object","additionalProperties":false,"required":["type","h","w"],"properties":{"type":{"const":"rect"},"h":{"type":"number"},"w":{"type":"number"}}}]}')
	@:variant(this.makeRenameConstructorSchema(), 'Types.RenameConstructor', '{"oneOf":[{"type":"object","additionalProperties":false,"required":["a"],"properties":{"a":{"type":"object","additionalProperties":false,"required":["v"],"properties":{"v":{"type":"integer"}}}}},{"type":"object","additionalProperties":false,"required":["b"],"properties":{"b":{"type":"object","additionalProperties":false,"required":["v"],"properties":{"v":{"type":"string"}}}}}]}')
	@:variant(this.makeTreeSchema(), 'Anon0', '{"type":"object","additionalProperties":false,"required":["children","name"],"properties":{"children":{"type":"array","items":{"$$ref":"#/$$defs/Anon0"}},"name":{"type":"string"}}}')
	@:variant(this.makeAltitudeSchema(), 'Anon0', '{"type":"object","additionalProperties":false,"required":["alt"],"properties":{"alt":{"type":"number"}}}')
	public function writeRef(schema:Schema, id:String, def:String) {
		final output = JsonSchema.write(schema);
		asserts.assert(output.indexOf('$HEADER,"$$ref":"#/$$defs/$id"') == 1);
		asserts.assert(output.indexOf('"$id":$def') > 0);
		return asserts.done();
	}
	
	public function writeCustomNames() {
		final schema = tink.Json.schema(Renamed);
		final id = 'Anon0';
		final def = '{"type":"object","additionalProperties":false,"required":["renamed"],"properties":{"renamed":{"type":"string"},"maybe":{"type":["integer","null"]},"opt":{"type":"integer"}}}';
		asserts.assert(JsonSchema.write(schema) == '{$HEADER,"$$ref":"#/$$defs/$id","$$defs":{"$id":$def}}');
		return asserts.done();
	}
	
	public function writeWrappedInt() {
		final output = JsonSchema.write(tink.Json.schema(WrappedInt));
		final def = '{"type":"object","additionalProperties":false,"required":["x"],"properties":{"x":{"type":"integer"}}}';
		asserts.assert(output.indexOf(def) > 0);
		asserts.assert(output.indexOf('"value"') == -1);
		return asserts.done();
	}
	
	public function writePresenceShape() {
		final schema = tink.Json.schema(PresenceShape);
		final output = JsonSchema.write(schema);
		asserts.assert(output.indexOf('"const":"1"') > 0);
		asserts.assert(output.indexOf('"const":"circle"') > 0);
		asserts.assert(output.indexOf('"const":"rect"') > 0);
		asserts.assert(output.indexOf('"radius"') > 0);
		asserts.assert(output.indexOf('"w"') > 0);
		return asserts.done();
	}

	public function writeJsonRpcMessage() {
		final output = JsonSchema.write(tink.Json.schema(JsonRpcMessage));
		asserts.assert(output.indexOf('"const":"2.0"') > 0);
		asserts.assert(output.indexOf('"error"') > 0);
		asserts.assert(output.indexOf('"result"') > 0);
		asserts.assert(output.indexOf('"method"') > 0);
		asserts.assert(output.indexOf('"id"') > 0);
		asserts.assert(output.indexOf('"params"') > 0);
		return asserts.done();
	}
	
	#if nodejs
	@:variant(tink.Json.schema(String), [tink.Json.stringify('foo')], ['1'])
	@:variant(tink.Json.schema(Int), [tink.Json.stringify(1)], ['"1"'])
	@:variant(tink.Json.schema(Float), [tink.Json.stringify(1.2)], ['"1"'])
	@:variant(tink.Json.schema(UInt), ['1'], ['-1', '1.5'])
	@:variant(tink.Json.schema(haxe.io.Bytes), [tink.Json.stringify(haxe.io.Bytes.alloc(10))], ['1'])
	@:variant(this.makeNullableStringSchema(), ['"foo"', 'null'], ['1'])
	
	@:variant(this.makeColorSchema(), [
		this.stringifyColor(White),
		this.stringifyColor(Hsv({hue: 0.1, saturation: 0.2, value: 0.3})),
		this.stringifyColor(Hsl({hue: 0.1, saturation: 0.2, lightness: 0.3})),
	], ['"Black"'])
	@:variant(this.makeShapeSchema(), [
		this.stringifyShape(Dot),
		this.stringifyShape(Circle(1.5)),
		this.stringifyShape(Rect(1.0, 2.0)),
	], ['"Dot"', '{"type":"triangle"}', '{"type":"circle","radius":"1"}'])
	@:variant(this.makeTreeSchema(), [
		this.stringifyTree({name: 'root', children: [{name: 'leaf', children: []}]}),
	], ['{"name":"root"}', '{"name":"root","children":[{"name":1,"children":[]}]}'])
	@:variant(this.makeStringMapSchema(), [tink.Json.stringify(['foo' => 1])], ['[["foo","bar"]]'])
	@:variant(this.makeArraySchema(), [tink.Json.stringify(['foo', 'bar'])], ['[1,2]'])
	@:variant(this.makeDynamicAccessSchema(), [tink.Json.stringify(({foo: 'bar'}:haxe.DynamicAccess<String>))], ['{"foo":1}'])
	@:variant(this.makeEnumAbstractSchema(), [this.stringifyEnumAbstract(Mon)], ['7'])
	@:variant(this.makeAsNumberSchema(), [this.stringifyAsNumber()], ['"1.5"', '{"value":1.5}'])
	@:variant(this.makeWrappedIntSchema(), [this.stringifyWrappedInt()], ['{"value":5}', '{"x":"5"}'])
	@:variant(this.makeAltitudeSchema(), [this.stringifyAltitude()], ['{"value":100}', '{"alt":"100"}'])
	public function validate(schema:Schema, valid:Array<String>, invalid:Array<String>) {
		final validate = new Ajv().compile(haxe.Json.parse(JsonSchema.write(schema)));
		for(value in valid) asserts.assert(validate(haxe.Json.parse(value)));
		for(value in invalid) asserts.assert(!validate(haxe.Json.parse(value)));
		return asserts.done();
	}
	#end
	
	inline function stringifyColor(v:Color) {
		return tink.Json.stringify(v);
	}
	
	inline function stringifyShape(v:Shape) {
		return tink.Json.stringify(v);
	}
	
	inline function stringifyTree(v:Tree) {
		return tink.Json.stringify(v);
	}
	
	inline function stringifyEnumAbstract(v:Weekday) {
		return tink.Json.stringify(v);
	}
	
	inline function stringifyAsNumber() {
		return tink.Json.stringify(new AsNumber(1.5));
	}
	
	inline function stringifyWrappedInt() {
		return tink.Json.stringify(new WrappedInt(5));
	}
	
	inline function stringifyAltitude() {
		return tink.Json.stringify(new Altitude(100));
	}
	
	inline function makeColorSchema():Schema {
		return tink.Json.schema(Color);
	}
	inline function makeShapeSchema():Schema {
		return tink.Json.schema(Shape);
	}
	inline function makeRenameConstructorSchema():Schema {
		return tink.Json.schema(RenameConstructor);
	}
	inline function makeTreeSchema():Schema {
		return tink.Json.schema(Tree);
	}
	inline function makeNullableStringSchema():Schema {
		return tink.Json.schema(NullableString);
	}
	inline function makeStringMapSchema():Schema {
		return tink.Json.schema(StringMap);
	}
	inline function makeArraySchema():Schema {
		return tink.Json.schema(StringArray);
	}
	inline function makeDynamicAccessSchema():Schema {
		return tink.Json.schema(StringDynamicAccess);
	}
	inline function makeEnumAbstractSchema():Schema {
		return tink.Json.schema(Weekday);
	}
	inline function makePairSchema():Schema {
		return tink.Json.schema(StringIntPair);
	}
	inline function makeEitherSchema():Schema {
		return tink.Json.schema(StringOrInt);
	}
	inline function makeAsNumberSchema():Schema {
		return tink.Json.schema(AsNumber);
	}
	inline function makeWrappedIntSchema():Schema {
		return tink.Json.schema(WrappedInt);
	}
	inline function makeAltitudeSchema():Schema {
		return tink.Json.schema(Altitude);
	}
}

#if nodejs
@:jsRequire('ajv/dist/2020', 'default')
extern class Ajv {
	function new();
	function compile(schema:Dynamic):Dynamic->Bool;
}
#end

private enum Color {
	White;
	Hsl(value:{ hue:Float, saturation:Float, lightness:Float });
	Hsv(hsv:{ hue:Float, saturation:Float, value:Float });
}

enum Shape {
	@:json('dot') Dot;
	@:json({type: 'circle'}) Circle(radius:Float);
	@:json({type: 'rect'}) Rect(w:Float, h:Float);
}

enum abstract Weekday(Int) {
	final Mon;
	final Tue;
	final Wed;
	final Thu;
	final Fri;
	final Sat;
	final Sun;
}

typedef Tree = {
	final name:String;
	final children:Array<Tree>;
}

typedef Renamed = {
	@:json('renamed') final original:String;
	final opt:haxe.ds.Option<Int>;
	@:optional final maybe:Int;
}

typedef NullableString = Null<String>;
typedef StringMap = Map<String, Int>;
typedef StringArray = Array<String>;
typedef StringDynamicAccess = DynamicAccess<String>;
typedef StringIntPair = tink.core.Pair<String, Int>;
typedef StringOrInt = haxe.ds.Either<String, Int>;

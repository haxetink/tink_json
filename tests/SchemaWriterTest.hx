package;

import tink.json.schema.Schema;
import tink.json.schema.SchemaWriter;
import tink.json.schema.JsonSchema;
import haxe.DynamicAccess;

@:asserts
class SchemaWriterTest {
	public function new() {}
	
	
	@:variant(SPrimitive(PString(null)), '{"type":"string"}')
	@:variant(SPrimitive(PString('White')), '{"type":"string","const":"White"}')
	@:variant(SOneOf([SPrimitive(PString('White'))]), '{"oneOf":[{"type":"string","const":"White"}]}')
	@:variant(STuple([SPrimitive(PInt(null)),SPrimitive(PString(null))]), '{"type":"array","additionalItems":false,"items":[{"type":"integer"},{"type":"string"}]}')
	
	@:variant(tink.Json.schema(String), '{"type":"string"}')
	@:variant(tink.Json.schema(Int), '{"type":"integer"}')
	@:variant(tink.Json.schema(Float), '{"type":"number"}')
	@:variant(tink.Json.schema(Date), '{"type":"number"}')
	@:variant(tink.Json.schema(Bool), '{"type":"boolean"}')
	@:variant(tink.Json.schema(haxe.io.Bytes), '{"type":"string","pattern":"^[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789\\\\+/=]*$"}')
	@:variant(this.makeColorSchema(), '{"oneOf":[{"type":"string","const":"White"},{"type":"object","additionalProperties":false,"required":["Hsl"],"properties":{"Hsl":{"type":"object","additionalProperties":false,"required":["value"],"properties":{"value":{"type":"object","additionalProperties":false,"required":["hue","lightness","saturation"],"properties":{"hue":{"type":"number"},"lightness":{"type":"number"},"saturation":{"type":"number"}}}}}}},{"type":"object","additionalProperties":false,"required":["Hsv"],"properties":{"Hsv":{"type":"object","additionalProperties":false,"required":["hue","saturation","value"],"properties":{"hue":{"type":"number"},"saturation":{"type":"number"},"value":{"type":"number"}}}}}]}')
	@:variant(this.makeStringMapSchema(), '{"type":"array","items":{"type":"array","additionalItems":false,"items":[{"type":"string"},{"type":"integer"}]}}')
	@:variant(this.makeArraySchema(), '{"type":"array","items":{"type":"string"}}')
	@:variant(this.makeDynamicAccessSchema(), '{"type":"object","additionalProperties":false,"patternProperties":{".+":{"type":"string"}}}')
	@:variant(this.makeEnumAbstractSchema(), '{"enum":[0,1,2,3,4,5,6]}')
	
	@:variant(SNullable(tink.Json.schema(String)), '{"type":["string","null"]}')
	@:variant(SNullable(tink.Json.schema(Int)), '{"type":["integer","null"]}')
	@:variant(SNullable(tink.Json.schema(Float)), '{"type":["number","null"]}')
	@:variant(SNullable(tink.Json.schema(Date)), '{"type":["number","null"]}')
	@:variant(SNullable(tink.Json.schema(Bool)), '{"type":["boolean","null"]}')
	@:variant(SNullable(tink.Json.schema(haxe.io.Bytes)), '{"type":["string","null"],"pattern":"^[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789\\\\+/=]*$"}')
	@:variant(SNullable(this.makeColorSchema()), '{"oneOf":[{"type":"string","const":"White"},{"type":"object","additionalProperties":false,"required":["Hsl"],"properties":{"Hsl":{"type":"object","additionalProperties":false,"required":["value"],"properties":{"value":{"type":"object","additionalProperties":false,"required":["hue","lightness","saturation"],"properties":{"hue":{"type":"number"},"lightness":{"type":"number"},"saturation":{"type":"number"}}}}}}},{"type":"object","additionalProperties":false,"required":["Hsv"],"properties":{"Hsv":{"type":"object","additionalProperties":false,"required":["hue","saturation","value"],"properties":{"hue":{"type":"number"},"saturation":{"type":"number"},"value":{"type":"number"}}}}},{"type":"null"}]}')
	@:variant(SNullable(this.makeStringMapSchema()), '{"type":["array","null"],"items":{"type":"array","additionalItems":false,"items":[{"type":"string"},{"type":"integer"}]}}')
	@:variant(SNullable(this.makeArraySchema()), '{"type":["array","null"],"items":{"type":"string"}}')
	@:variant(SNullable(this.makeDynamicAccessSchema()), '{"type":["object","null"],"additionalProperties":false,"patternProperties":{".+":{"type":"string"}}}')
	@:variant(SNullable(this.makeEnumAbstractSchema()), '{"enum":[0,1,2,3,4,5,6,null]}')
	public function write(schema:SchemaType, output:String) {
		asserts.assert(JsonSchema.write(schema) == output);
		return asserts.done();
	}
	
	#if nodejs
	
	@:variant(SNullable(SPrimitive(PString(null))), ['"foo"', 'null'], ['1'])
	@:variant(SNullable(this.makeColorSchema()), [this.stringifyColor(White), 'null'], ['"Black"'])
	
	
	@:variant(tink.Json.schema(String), [tink.Json.stringify('foo')],['1'])
	@:variant(tink.Json.schema(Int), [tink.Json.stringify(1)],['"1"'])
	@:variant(tink.Json.schema(Float), [tink.Json.stringify(1.2)],['"1"'])
	@:variant(tink.Json.schema(haxe.io.Bytes), [tink.Json.stringify(haxe.io.Bytes.alloc(10))],['1'])
	
	@:variant(this.makeColorSchema(), [
		this.stringifyColor(White),
		this.stringifyColor(Hsv({hue: 0.1, saturation: 0.2, value: 0.3})),
		this.stringifyColor(Hsl({hue: 0.1, saturation: 0.2, lightness: 0.3})),
	], ['"Black"'])
	@:variant(this.makeStringMapSchema(), [tink.Json.stringify(['foo' => 1])], ['[["foo","bar"]]'])
	@:variant(this.makeArraySchema(), [tink.Json.stringify(['foo', 'bar'])], ['[1,2]'])
	@:variant(this.makeDynamicAccessSchema(), [tink.Json.stringify({foo: 'bar'})], ['{"foo":1}'])
	@:variant(this.makeEnumAbstractSchema(), [this.stringifyEnumAbstract(Mon)], ['7'])
	public function validate(schema:SchemaType, valid:Array<String>, invalid:Array<String>) {
		final schema = JsonSchema.write(schema);
		// trace(schema);
		trace(valid);
		final validate = new Ajv().compile(haxe.Json.parse(schema));
		for(value in valid) asserts.assert(validate(haxe.Json.parse(value)));
		for(value in invalid) asserts.assert(!validate(haxe.Json.parse(value)));
		return asserts.done();
	}
	#end
	
	inline function stringifyColor(v:Color) {
		return tink.Json.stringify(v);
	}
	
	inline function stringifyEnumAbstract(v:Weekday) {
		return tink.Json.stringify(v);
	}
	
	inline function makeColorSchema():SchemaType {
		return tink.Json.schema(Color);
		// return SOneOf({list: [
		// 	SPrimitive(PString({const:'White'})),
		// 	SObject({fields: [
		// 		{name: 'Hsl', type: SObject({fields: [
		// 			{name: 'value', type: SObject({fields: [
		// 				{name: 'hue', type: SPrimitive(PFloat({}))},
		// 				{name: 'saturation', type: SPrimitive(PFloat({}))},
		// 				{name: 'lightness', type: SPrimitive(PFloat({}))},
		// 			]})}
		// 		]})}
		// 	]}),
		// 	SObject({fields: [
		// 		{name: 'Hsv', type: SObject({fields: [
		// 			{name: 'hue', type: SPrimitive(PFloat({}))},
		// 			{name: 'saturation', type: SPrimitive(PFloat({}))},
		// 			{name: 'value', type: SPrimitive(PFloat({}))},
		// 		]})}
		// 	]}),
		// ]});
	}
	inline function makeStringMapSchema():SchemaType {
		return tink.Json.schema(StringMap);
	}
	inline function makeArraySchema():SchemaType {
		return tink.Json.schema(StringArray);
	}
	inline function makeDynamicAccessSchema():SchemaType {
		return tink.Json.schema(StringDynamicAccess);
	}
	inline function makeEnumAbstractSchema():SchemaType {
		return tink.Json.schema(Weekday);
	}
}

#if nodejs
@:jsRequire('ajv', 'default')
extern class Ajv {
	function new();
	function compile(schema:String):String->Bool;
}

private enum Color {
	White;
	Hsl(value:{ hue:Float, saturation:Float, lightness:Float });
	Hsv(hsv:{ hue:Float, saturation:Float, value:Float });
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

private typedef StringMap = Map<String, Int>;
private typedef StringArray = Array<String>;
private typedef StringDynamicAccess = DynamicAccess<String>;
#end
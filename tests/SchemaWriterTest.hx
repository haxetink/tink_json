package;

import tink.json.schema.Schema;
import tink.json.schema.SchemaWriter;
import tink.json.schema.JsonSchema;

@:asserts
class SchemaWriterTest {
	public function new() {}
	
	
	@:variant(SPrimitive(PString({})), '{"type":"string"}')
	@:variant(SPrimitive(PString({const:'White'})), '{"type":"string","const":"White"}')
	@:variant(SOneOf({list: [SPrimitive(PString({const:'White'}))]}), '{"oneOf":[{"type":"string","const":"White"}]}')
	@:variant(this.makeColorSchema(), '{"oneOf":[{"type":"string","const":"White"},{"type":"object","additionalProperties":false,"required":["Hsl"],"properties":{"Hsl":{"type":"object","additionalProperties":false,"required":["value"],"properties":{"value":{"type":"object","additionalProperties":false,"required":["hue","lightness","saturation"],"properties":{"hue":{"type":"number"},"lightness":{"type":"number"},"saturation":{"type":"number"}}}}}}},{"type":"object","additionalProperties":false,"required":["Hsv"],"properties":{"Hsv":{"type":"object","additionalProperties":false,"required":["hue","saturation","value"],"properties":{"hue":{"type":"number"},"saturation":{"type":"number"},"value":{"type":"number"}}}}}]}')
	@:variant(STuple({values:[SPrimitive(PInt({})),SPrimitive(PString({}))]}), '{"type":"array","additionalItems":false,"items":[{"type":"integer"},{"type":"string"}]}')
	public function write(schema:SchemaType, output:String) {
		
		
		asserts.assert(JsonSchema.write(schema) == output);
		return asserts.done();
	}
	
	#if nodejs
	@:variant(this.makeColorSchema(), [
		this.makeColor(White),
		this.makeColor(Hsv({hue: 0.1, saturation: 0.2, value: 0.3})),
		this.makeColor(Hsl({hue: 0.1, saturation: 0.2, lightness: 0.3})),
	])
	@:variant(SNullable(SPrimitive(PString({}))), ['"foo"', 'null'])
	@:variant(SNullable(this.makeColorSchema()), [this.makeColor(White), 'null'])
	@:variant(this.makeStringMap(), [tink.Json.stringify(['foo' => 1])])
	public function validate(schema:SchemaType, values:Array<String>) {
		final schema = JsonSchema.write(schema);
		final validate = new Ajv().compile(haxe.Json.parse(schema));
		for(value in values) asserts.assert(validate(haxe.Json.parse(value)));
		return asserts.done();
	}
	#end
	
	inline function makeColor(v:Color) {
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
	inline function makeStringMap():SchemaType {
		return tink.Json.schema(StringMap);
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

private typedef StringMap = Map<String, Int>;
#end
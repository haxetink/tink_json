package tink.json.schema;

import tink.json.schema.Schema;

using tink.json.schema.JsonSchema.NullableTools;

class JsonSchema {
	public static function write(schema:SchemaType):String {
		return writeNullable(schema, false);
	}
	
	public static function writeNullable(schema:SchemaType, nullable:Bool):String {
		return switch schema {
			case SNullable(v): writeNullable(v, true);
			case SPrimitive(p): writePrimitive(p, nullable);
			case STuple(s): writeTuple(s, nullable);
			case SArray(s): writeArray(s, nullable);
			case SObject(s): writeObject(s, nullable);
			case SOneOf(s): writeOneOf(s, nullable);
		}
	}
	
	static function writeType(type:String, nullable:Bool) {
		type = nullable ? '["$type","null"]' : '"$type"';
		return '"type":$type';
	}
	
	static function writePrimitive(type:PrimitiveType, nullable:Bool) {
		inline function make(t:String, rest:String) {
			return '{${writeType(t, nullable)}${rest.or('')}}';
		}
		
		return switch type {
			case PString(s):
				make('string', s.const.map(v -> ',"const":${tink.Json.stringify(v)}'));
			case PFloat(s):
				make('number', s.const.map(v -> ',"const":${tink.Json.stringify(v)}'));
			case PInt(s):
				make('integer', s.const.map(v -> ',"const":${tink.Json.stringify(v)}'));
			case PBool(s):
				make('boolean', s.const.map(v -> ',"const":${tink.Json.stringify(v)}'));
		}
	}
	
	static function writeTuple(tuple:TupleSchema, nullable:Bool) {
		return '{${writeType('array', nullable)},"additionalItems":false,"items":[${tuple.values.map(write).join(',')}]}';
	}
	
	static function writeArray(array:ArraySchema, nullable:Bool) {
		return '{${writeType('array', nullable)},"items":${write(array.type)}}';
	}
	
	static function writeObject(object:ObjectSchema, nullable:Bool) {
		return '{${writeType('object', nullable)},"additionalProperties":false,"required":[${object.fields.filter(f -> !f.optional).map(v -> '"${v.name}"').join(',')}],"properties":{${object.fields.map(f -> '"${f.name}":${write(f.type)}').join(',')}}}';
	}
	
	static function writeOneOf(oneOf:OneOfSchema, nullable:Bool) {
		var entries = oneOf.list.map(write).join(',');
		if(nullable) entries += ',{"type":"null"}';
		return '{"oneOf":[$entries]}';
	}
}

class NullableTools {
	public static function map<T,R>(v:Null<T>, f:T->R):Null<R> {
		return v == null ? null : f(v);
	}
	public static function or<T>(v:Null<T>, fallback:T):T {
		return v == null ? fallback : v;
	}
}
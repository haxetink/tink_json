package tink.json.schema;

import tink.json.schema.Schema;

using tink.json.schema.JsonSchema.NullableTools;

class JsonSchema {
	public static function write(schema:SchemaType):String {
		return writeNullable(schema, false);
	}
	
	public static function writeNullable(schema:SchemaType, nullable:Bool):String {
		return switch schema {
			case SNullable(t): writeNullable(t, true);
			case SPrimitive(p): writePrimitive(p, nullable);
			case STuple(types): writeTuple(types, nullable);
			case SArray(type): writeArray(type, nullable);
			case SObject(fields): writeObject(fields, nullable);
			case SDynamicAccess(type): writeDynamicAccess(type, nullable);
			case SEnum(entries): writeEnum(entries, nullable);
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
			case PString(const):
				make('string', const.map(v -> ',"const":${tink.Json.stringify(v)}'));
			case PFloat(const):
				make('number', const.map(v -> ',"const":${tink.Json.stringify(v)}'));
			case PInt(const):
				make('integer', const.map(v -> ',"const":${tink.Json.stringify(v)}'));
			case PBool(const):
				make('boolean', const.map(v -> ',"const":${tink.Json.stringify(v)}'));
			case PRegex(pattern):
				make('string', ',"pattern":${tink.Json.stringify(pattern)}');
		}
	}
	
	static function writeTuple(types:Array<SchemaType>, nullable:Bool) {
		return '{${writeType('array', nullable)},"additionalItems":false,"items":[${types.map(write).join(',')}]}';
	}
	
	static function writeArray(type:SchemaType, nullable:Bool) {
		return '{${writeType('array', nullable)},"items":${write(type)}}';
	}
	
	static function writeObject(fields:Array<ObjectFieldSchema>, nullable:Bool) {
		return '{${writeType('object', nullable)},"additionalProperties":false,"required":[${fields.filter(f -> !f.optional).map(v -> '"${v.name}"').join(',')}],"properties":{${fields.map(f -> '"${f.name}":${write(f.type)}').join(',')}}}';
	}
	
	static function writeDynamicAccess(type:SchemaType, nullable:Bool) {
		return '{${writeType('object', nullable)},"additionalProperties":false,"patternProperties":{".+":${write(type)}}}';
	}
	
	static function writeEnum(entries:Array<Primitive>, nullable:Bool) {
		var entries = [for(e in entries) haxe.Json.stringify(e)].join(',');
		if(nullable) entries += ',null';
		return '{"enum":[${entries}]}';
	}
	
	static function writeOneOf(options:Array<SchemaType>, nullable:Bool) {
		var entries = options.map(write).join(',');
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
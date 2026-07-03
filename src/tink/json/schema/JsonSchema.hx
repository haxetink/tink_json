package tink.json.schema;

import tink.json.schema.Schema;

class JsonSchema {
	public static inline var DRAFT = 'https://json-schema.org/draft/2020-12/schema';
	
	// haxe.Json.stringify is not used because some targets (e.g. php) escape '/',
	// which would make the output target-dependent
	static function quote(s:String):String {
		final buf = new StringBuf();
		buf.add('"');
		for(i in 0...s.length) {
			final c = StringTools.fastCodeAt(s, i);
			switch c {
				case '"'.code: buf.add('\\"');
				case '\\'.code: buf.add('\\\\');
				case '\n'.code: buf.add('\\n');
				case '\r'.code: buf.add('\\r');
				case '\t'.code: buf.add('\\t');
				case 0x08: buf.add('\\b');
				case 0x0C: buf.add('\\f');
				case c if(c < 0x20): buf.add('\\u' + StringTools.hex(c, 4));
				default: buf.addChar(c);
			}
		}
		buf.add('"');
		return buf.toString();
	}
	
	static function stringify(v:Dynamic):String {
		return switch Type.typeof(v) {
			case TNull: 'null';
			case TBool | TInt | TFloat: Std.string(v);
			case TClass(String): quote(v);
			case TClass(Array): '[${[for(x in (v:Array<Dynamic>)) stringify(x)].join(',')}]';
			default: '{${[for(f in Reflect.fields(v)) '${quote(f)}:${stringify(Reflect.field(v, f))}'].join(',')}}';
		}
	}
	
	public static function write(schema:Schema):String {
		final root = writeType(schema.root);
		final parts = ['"$$schema":${stringify(DRAFT)}'];
		
		if(root != '{}') parts.push(root.substr(1, root.length - 2));
		
		final ids = [for(id in schema.defs.keys()) id];
		if(ids.length > 0) {
			ids.sort(Reflect.compare);
			parts.push('"$$defs":{${ids.map(id -> '"$id":${writeType(schema.defs.get(id))}').join(',')}}');
		}
		
		return '{${parts.join(',')}}';
	}
	
	public static function writeType(schema:SchemaType):String {
		return writeNullable(schema, false);
	}
	
	static function writeNullable(schema:SchemaType, nullable:Bool):String {
		return switch schema {
			case SNullable(t): writeNullable(t, true);
			case SAny: '{}';
			case SPrimitive(p): writePrimitive(p, nullable);
			case SConst(v): writeConst(v, nullable);
			case STuple(types): writeTuple(types, nullable);
			case SArray(type): writeArray(type, nullable);
			case SObject(fields): writeObject(fields, nullable);
			case SDynamicAccess(type): writeDynamicAccess(type, nullable);
			case SEnum(entries): writeEnum(entries, nullable);
			case SOneOf(s): writeOneOf(s, nullable);
			case SRef(id): writeRef(id, nullable);
		}
	}
	
	static function writeSchemaType(type:String, nullable:Bool) {
		type = nullable ? '["$type","null"]' : '"$type"';
		return '"type":$type';
	}
	
	static function writePrimitive(type:PrimitiveType, nullable:Bool) {
		inline function make(t:String, rest:Null<String>) {
			return '{${writeSchemaType(t, nullable)}${rest == null ? '' : rest}}';
		}
		
		return switch type {
			case PString(const):
				make('string', const == null ? null : ',"const":${stringify(const)}');
			case PFloat(const):
				make('number', const == null ? null : ',"const":${stringify(const)}');
			case PInt(const, minimum):
				make('integer',
					(const == null ? '' : ',"const":${stringify(const)}')
					+ (minimum == null ? '' : ',"minimum":${stringify(minimum)}')
				);
			case PBool(const):
				make('boolean', const == null ? null : ',"const":${stringify(const)}');
			case PDate:
				make('number', ',"description":"Unix timestamp in milliseconds"');
			case PRegex(pattern):
				make('string', ',"pattern":${stringify(pattern)}');
		}
	}
	
	static function writeConst(value:Any, nullable:Bool) {
		final const = '{"const":${stringify(value)}}';
		return nullable ? '{"oneOf":[$const,{"type":"null"}]}' : const;
	}
	
	static function writeTuple(types:Array<SchemaType>, nullable:Bool) {
		return '{${writeSchemaType('array', nullable)},"prefixItems":[${types.map(writeType).join(',')}],"items":false,"minItems":${types.length}}';
	}
	
	static function writeArray(type:SchemaType, nullable:Bool) {
		return '{${writeSchemaType('array', nullable)},"items":${writeType(type)}}';
	}
	
	static function writeObject(fields:Array<ObjectFieldSchema>, nullable:Bool) {
		final required = fields.filter(f -> !f.optional).map(f -> '"${f.name}"');
		return '{${writeSchemaType('object', nullable)},"additionalProperties":false,"required":[${required.join(',')}],"properties":{${fields.map(f -> '"${f.name}":${writeType(f.type)}').join(',')}}}';
	}
	
	static function writeDynamicAccess(type:SchemaType, nullable:Bool) {
		return '{${writeSchemaType('object', nullable)},"additionalProperties":${writeType(type)}}';
	}
	
	static function writeEnum(entries:Array<Primitive>, nullable:Bool) {
		var entries = [for(e in entries) stringify(e)].join(',');
		if(nullable) entries += ',null';
		return '{"enum":[${entries}]}';
	}
	
	static function writeOneOf(options:Array<SchemaType>, nullable:Bool) {
		var entries = options.map(writeType).join(',');
		if(nullable) entries += ',{"type":"null"}';
		return '{"oneOf":[$entries]}';
	}
	
	static function writeRef(id:String, nullable:Bool) {
		final ref = '{"$$ref":${stringify('#/$$defs/$id')}}';
		return nullable ? '{"oneOf":[$ref,{"type":"null"}]}' : ref;
	}
}

package tink.json.schema;

typedef Schema = {
	final root:SchemaType;
	final defs:Map<String, SchemaType>;
}

enum SchemaType {
	SAny;
	SNullable(type:SchemaType);
	SPrimitive(primitive:PrimitiveType);
	SConst(value:Any);
	STuple(types:Array<SchemaType>);
	SArray(type:SchemaType);
	SObject(fields:Array<ObjectFieldSchema>);
	SDynamicAccess(type:SchemaType);
	SEnum(entries:Array<Primitive>);
	SOneOf(options:Array<SchemaType>);
	SRef(id:String);
}

enum PrimitiveType {
	PString(const:Null<String>);
	PFloat(const:Null<Float>);
	PInt(const:Null<Int>, ?minimum:Int);
	PBool(const:Null<Bool>);
	PDate;
	PRegex(pattern:String);
}

typedef ObjectFieldSchema = {
	name:String,
	type:SchemaType,
	?optional:Bool,
}

abstract Primitive(Dynamic) from Int from Float from Bool from String {}

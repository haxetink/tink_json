package tink.json.schema;

enum SchemaType {
	SNullable(type:SchemaType);
	SPrimitive(primitive:PrimitiveType);
	STuple(types:Array<SchemaType>);
	SArray(type:SchemaType);
	SObject(fields:Array<ObjectFieldSchema>);
	SDynamicAccess(type:SchemaType);
	SEnum(entries:Array<Primitive>);
	SOneOf(options:Array<SchemaType>);
}

enum PrimitiveType {
	PString(const:Null<String>);
	PFloat(const:Null<Float>);
	PInt(const:Null<Int>);
	PBool(const:Null<Bool>);
	PRegex(pattern:String);
	// PTimestamp(s:TimestampSchema);
}

typedef ObjectFieldSchema = {
	name:String,
	type:SchemaType,
	?optional:Bool,
}

abstract Primitive(Dynamic) from Int from Float from Bool from String {}
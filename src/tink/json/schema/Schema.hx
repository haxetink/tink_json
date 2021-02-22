package tink.json.schema;

enum SchemaType {
	SNullable(t:SchemaType);
	SPrimitive(s:PrimitiveType);
	STuple(s:TupleSchema);
	SArray(s:ArraySchema);
	SObject(s:ObjectSchema);
	// SEnum(s:EnumSchema); // primitive only
	SOneOf(s:OneOfSchema);
}

enum PrimitiveType {
	PString(s:StringSchema);
	PFloat(s:FloatSchema);
	PInt(s:IntSchema);
	PBool(s:BoolSchema);
	// PTimestamp(s:TimestampSchema);
}


typedef PrimitiveSchema<T> = {
	?const:T,
}

typedef StringSchema = PrimitiveSchema<String>;

typedef FloatSchema = PrimitiveSchema<Float>;

typedef IntSchema = PrimitiveSchema<Int>;

typedef BoolSchema = PrimitiveSchema<Bool>;

typedef TimestampSchema = FloatSchema;

typedef TupleSchema = {
	values:Array<SchemaType>,
}

typedef ArraySchema = {
	type:SchemaType,
}

typedef ObjectSchema = {
	fields:Array<ObjectFieldSchema>,
}

typedef EnumSchema = {
	list:Array<SchemaType>,
}

typedef OneOfSchema = {
	list:Array<SchemaType>,
}


typedef ObjectFieldSchema = {
	name:String,
	type:SchemaType,
	?optional:Bool,
}
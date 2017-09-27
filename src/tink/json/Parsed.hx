package tink.json;

@:genericBuild(tink.json.macros.Macro.buildParsed())
class Parsed<T> {}

@:genericBuild(tink.json.macros.Macro.buildParsedFields())
class ParsedFields<T> {}
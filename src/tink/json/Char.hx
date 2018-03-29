package tink.json;

#if tink_json_compact_code
abstract Char(String) from String to String {

  @:from macro static function ofAny(i:Int) 
    return macro $v{String.fromCharCode(i)};
  
  public inline function toString()
    return this;
}
#else
abstract Char(Int) from Int to Int {
  public inline function toString() 
    return String.fromCharCode(this);
}
#end
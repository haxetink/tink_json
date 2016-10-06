package tink.json;

enum Value {
  VNumber(f:Float);
  VString(s:String);
  VNull;
  VBool(b:Bool);
  VArray(a:Array<Value>);
  VObject(a:Array<tink.core.Named<Value>>);
}
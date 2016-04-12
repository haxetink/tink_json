package tink.json.macros;

import haxe.macro.Expr;
import haxe.macro.Type;

typedef FieldInfo = {
  name:String,
  pos:Position,
  type:Type,
  expr:Expr,
  optional:Bool
}
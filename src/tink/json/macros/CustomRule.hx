package tink.json.macros;

import haxe.macro.Expr;

enum CustomRule {
  WithClass(cls:Expr);
  WithFunction(expr:Expr);
}
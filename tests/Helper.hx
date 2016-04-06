package;

import haxe.macro.Expr;

class Helper {

  macro static public function roundtrip(e:Expr, ?noHaxe:Bool) {
    return macro @:pos(e.pos) {
      var original = $e,
          roundtripped = original;
      roundtripped = tink.Json.parse(tink.Json.stringify(original));
      structEq(original, roundtripped);
      ${
        if (noHaxe) macro $b{[]}
        else macro {
          structEq(original, haxe.Json.parse(tink.Json.stringify(original)));
          structEq(original, tink.Json.parse(haxe.Json.stringify(original)));          
        }
      }
    }
  }
  
  macro static public function test(e:Expr) {
    trace(haxe.macro.ExprTools.toString(haxe.macro.Context.getTypedExpr(haxe.macro.Context.typeExpr(e))));
    return e;
  }
    
}
package;

import haxe.macro.Expr;

class Helper {

  macro static public function roundtrip(e:Expr, ?noHaxe:Bool) {
    return macro @:pos(e.pos) {
      tink.core.Error.catchExceptions(function() {
        var original = $e,
            roundtripped = original;
        roundtripped = tink.Json.parse(tink.Json.stringify(original));
        
        var result = compare(original, roundtripped);
        return  ${
          if (noHaxe) macro result;
          else macro result
            .swap(compare(original, haxe.Json.parse(tink.Json.stringify(original))))
            .swap(compare(original, tink.Json.parse(haxe.Json.stringify(original))))
        }
      }).flatten();
    }
  }
  
  macro static public function test(e:Expr) {
    trace(haxe.macro.ExprTools.toString(haxe.macro.Context.getTypedExpr(haxe.macro.Context.typeExpr(e))));
    return e;
  }
    
}
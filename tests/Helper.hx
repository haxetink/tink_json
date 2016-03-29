package;

import haxe.macro.Expr;

class Helper {

  macro static public function roundtrip(e:Expr) {
    return macro {
      var original = $e,
          roundtripped = original;
      roundtripped = tink.Json.parse(haxe.Json.stringify(original));
      structEq(original, roundtripped);
    }
  }
  
}
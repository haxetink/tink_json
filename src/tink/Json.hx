package tink;

import haxe.macro.*;

#if macro
using tink.MacroApi;
#end

class Json { 

  static macro public function parse(e:Expr) 
    return 
      switch e {
        case macro ($e : $ct):
          macro new tink.json.Parser<$ct>().tryParse($e);
        case _:
          switch Context.getExpectedType() {
            case null:
              e.reject('Cannot determine expected type');
            case _.toComplex() => ct:
              macro @:pos(e.pos) new tink.json.Parser<$ct>().parse($e);
          }
      }
      
  static macro public function stringify(e:Expr) {
    var ct = e.typeof().sure().toComplex();
    return macro @:pos(e.pos) new tink.json.Writer<$ct>().write($e);
  }
}
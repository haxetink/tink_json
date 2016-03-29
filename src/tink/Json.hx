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
          macro new tink.json.Parser<$ct>().parse($e);
        case _:
          switch Context.getExpectedType() {
            case null:
              e.reject('Cannot determine expected type');
            case _.toComplex() => ct:
              macro tink.CoreApi.OutcomeTools.sure(new tink.json.Parser<$ct>().parse($e));
          }
      }
  
}
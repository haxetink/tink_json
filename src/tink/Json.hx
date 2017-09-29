package tink;

import haxe.macro.*;

#if macro
using StringTools;
using tink.CoreApi;
using tink.MacroApi;
#end

class Json { 

  static macro public function parse(e:Expr) 
    return 
      switch e {
        case macro ($v : $ct):
          switch ct.toType() {
            case Success(t = TAbstract(_.get() => {type: TType(_, [_.toComplex() => ct, _])}, _)) if(t.getID().startsWith('tink.json.Parsed')):
              macro @:pos(e.pos) new tink.json.Parser<$ct>().tryParsed($v);
            default:
              macro @:pos(e.pos) new tink.json.Parser<$ct>().tryParse($v);
          }
        case _:
          switch Context.getExpectedType() {
            case null:
              e.reject('Cannot determine expected type');
            case t = TAbstract(_.get() => {type: TType(_, [_.toComplex() => ct, _])}, _) if(t.getID().startsWith('tink.json.Parsed')):
              macro @:pos(e.pos) new tink.json.Parser<$ct>().parsed($e);
            case _.toComplex() => ct:
              macro @:pos(e.pos) new tink.json.Parser<$ct>().parse($e);
          }
      }
      
  static macro public function stringify(e:Expr) {
    var ct = e.typeof().sure().toComplex();
    return macro @:pos(e.pos) new tink.json.Writer<$ct>().write($e);
  }
  
}
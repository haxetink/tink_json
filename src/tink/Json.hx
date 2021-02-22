package tink;

import haxe.macro.*;

#if macro
using tink.MacroApi;
#end

class Json {

  static macro public function parse(e:Expr):ExprOf<String> {
    function forceTyping(t:Type)
      tink.json.macros.Macro.buildParser(t, e.pos);// workaround for https://github.com/HaxeFoundation/haxe/issues/9342
    return
      switch e {
        case macro ($e : $ct):
          forceTyping(ct.toType(e.pos).sure());
          macro new tink.json.Parser<$ct>().tryParse($e);
        case _:
          switch Context.getExpectedType() {
            case null:
              e.reject('Cannot determine expected type');
            case t:
              forceTyping(t);
              var ct = t.toComplex();
              macro @:pos(e.pos) (new tink.json.Parser<$ct>()).parse($e);
          }
      }
  }

  static macro public function stringify(e:ExprOf<String>) {
    var t = e.typeof().sure();

    tink.json.macros.Macro.buildWriter(t, e.pos);// workaround for https://github.com/HaxeFoundation/haxe/issues/9342

    var ct = t.toComplex();

    return macro @:pos(e.pos) new tink.json.Writer<$ct>().write($e);
  }

  static macro public function schema(e:Expr) {
    var t = Context.getType(e.toString());

    var ct = t.toComplex();

    return macro @:pos(e.pos) new tink.json.schema.SchemaWriter<$ct>().write();
  }
}
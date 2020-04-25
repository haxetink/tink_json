package tink.json;

#if macro
import haxe.macro.*;
using tink.MacroApi;
#end

abstract Serialized<T>(String) to String {
  #if macro
  static function resultType(ethis:Expr)
    return switch ethis.typeof().sure() {
      case TAbstract(_.get().module => 'tink.json.Serialized', [_.toComplex() => ct]):
        ct;
      default:
        throw 'assert';
    }
  #end

  macro public function parse(ethis) {
    var ct = resultType(ethis);
    return macro @:pos(ethis.pos) (tink.Json.parse($ethis) : $ct);
  }

  macro public function tryParse(ethis) {
    var ct = resultType(ethis);
    return macro @:pos(ethis.pos) tink.Json.parse(($ethis : $ct));
  }

  @:from static macro function ofExpr(e)
    return switch Context.getExpectedType() {
      case TAbstract(_, [_.toComplex() => ct]):
        macro @:pos(e.pos) tink.Json.stringify(($e : $ct));
      default: throw 'abstract';
    }
}
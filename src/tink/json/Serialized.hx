package tink.json;

#if macro
using tink.MacroApi;
#end

abstract Serialized<T>(String) to String {

  macro public function parse(ethis)
    return macro tink.core.Outcome.OutcomeTools.sure($ethis.tryParse());

  macro public function tryParse(ethis) 
    return switch ethis.typeof().sure() {
      case TAbstract(_.get().module => 'tink.json.Serialized', [_.toComplex() => ct]):
      
        macro @:pos(ethis.pos) tink.Json.parse(($ethis : $ct));
      default:
        throw 'assert';
    }
}
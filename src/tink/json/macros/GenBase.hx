package tink.json.macros;

import haxe.macro.Type;
import haxe.macro.Expr;
import tink.typecrawler.Generator;

using haxe.macro.Tools;
using tink.MacroApi;
using tink.CoreApi;

class GenBase {
  var customMeta:String;
  function new(customMeta) {
    this.customMeta = customMeta;
  }
  public function rescue(t:Type, pos:Position, gen:GenType) 
    return None;
      
  public function shouldIncludeField(c:ClassField, owner:Option<ClassType>):Bool
    return Helper.shouldIncludeField(c, owner);

  function processRepresentation(pos:Position, actual:Type, representation:Type, value:Expr):Expr
    return throw 'abstract';

  function processDynamic(pos:Position):Expr
    return throw 'abstract';    

  function processValue(pos:Position):Expr
    return throw 'abstract';    

  function processSerialized(pos:Position):Expr
    return throw 'abstract';

  function processCustom(custom:CustomRule, original:Type, gen:Type->Expr):Expr
    return throw 'abstract';

  public function drive(type:Type, pos:Position, gen:Type->Position->Expr):Expr
    return 
      switch Macro.getRepresentation(type, pos) {
        case Some(v):
          processRepresentation(pos, type, v, gen(v, pos));
        case None:
          switch type.getMeta().filter(function (m) return m.has(customMeta)) {
            case []: 
              switch type.reduce() {
                case TDynamic(null): 
                  processDynamic(pos);
                case TEnum(_.get().module => 'tink.json.Value', _): 
                  processValue(pos);
                case TAbstract(_.get().module => 'tink.json.Serialized', _): 
                  processSerialized(pos);
                default: 
                  gen(type, pos);
              }
            case v: 
              switch v[0].extract(customMeta)[0] {
                case { params: [custom] }: 
                  var rule:CustomRule = 
                    switch custom {
                      case { expr: EFunction(_, _) }: WithFunction(custom);
                      case _.typeof().sure().reduce() => TFun(_, _): WithFunction(custom);
                      default: WithClass(custom);
                    }
                  processCustom(rule, type, drive.bind(_, pos, gen));
                case v: v.pos.error('@$customMeta must have exactly one parameter');
              }
          }       
      }    
          
}
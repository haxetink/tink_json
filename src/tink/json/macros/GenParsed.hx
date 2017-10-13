package tink.json.macros;

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.ds.Option;
import tink.typecrawler.Crawler;
import tink.typecrawler.FieldInfo;
import tink.typecrawler.Generator;

using haxe.macro.Tools;
using tink.MacroApi;
using tink.CoreApi;

class GenParsed {
  static public var inst = new GenParsed();
  
  function new() {}
  static var SKIP = macro {this.skipValue(); null;}    
  
  public function wrap(placeholder:Expr, ct:ComplexType):Function
    return placeholder.func(macro:tink.json.Parsed.ParsedFields<$ct>);
  
  public function nullable(e) 
    return e;
    
  public function string() 
    return SKIP;
    
  public function int() 
    return SKIP;
    
  public function float() 
    return SKIP;
    
  public function bool() 
    return SKIP;
    
  public function date() 
    return SKIP;
    
  public function bytes() 
    return SKIP;
    
  public function map(k, v)               
    return SKIP;
    
  public function anon(fields:Array<FieldInfo>, ct) {
    
    var read = macro this.skipValue(),
        vars:Array<Var> = [],
        obj:Array<{ field:String, expr:Expr }> = [];
        
    for (f in fields) {
      var ct = f.type.reduce().toComplex(),
          name = 'v_' + f.name,
          jsonName = Macro.nativeName(f),
          optional = f.optional;
         
      var hasName = 'has$name';

      read = macro @:pos(f.pos) 
        if (__name__ == $v{jsonName}) {
          $i{hasName} = true;
          $i{name} = ${f.expr};
        }
        else $read;

      obj.push({
        field: f.name,
        expr: macro {
          exists: $i{hasName},
          fields: $i{name},
        },
      });
      vars.push({
        name: hasName,
        expr: macro false,
        type: macro : Bool,
      });
      vars.push({
        name: name,
        expr: macro null,
        type: macro:tink.json.Parsed.ParsedFields<$ct>,
      });
    };
        // trace(read.toString());
    var e = macro {
      
      ${EVars(vars).at()};
      
      var __start__ = this.pos;
      this.expect('{');
      if (!this.allow('}')) {
        do {
          var __name__ = this.parseString();
          this.expect(':');
          $read;
        } while (this.allow(','));
        this.expect('}');
      }
        
      function __missing__(field:String):Dynamic {
        return this.die('missing field "' + field + '"', __start__);
      };

      (${EObjectDecl(obj).at()} : tink.json.Parsed.ParsedFields<$ct>);
    }
    return e;
  }  
  
  public function array(e) 
    return SKIP;
    
  public function enm(constructors:Array<EnumConstructor>, ct, pos:Position, gen:GenType)
    return SKIP;
  
  public function enumAbstract(names:Array<Expr>, e:Expr, ct:ComplexType, pos:Position):Expr
    return SKIP;
  
  public function dyn(e, ct) 
    return SKIP;
    
  public function dynAccess(e)
    return SKIP;
    
  public function rescue(t:Type, pos:Position, gen:GenType) 
    return 
      switch Macro.getRepresentation(t, pos) {
        case Some(v):
          var rt = t.toComplex();
          var ct = v.toComplex();
          
          Some(macro @:pos(pos) {
            var __start__ = this.pos,
                rep = ${gen(v, pos)};
                
            try {
              (new tink.json.Representation<$ct>(rep) : $rt);
            }
            catch (e:Dynamic) {
              this.die(Std.string(e), __start__);
            }
          });
          
        default:
          None;
      }
    
  public function reject(t:Type) 
    return 'tink_json cannot parse ${t.toString()}. For parsing custom data, please see https://github.com/haxetink/tink_json#custom-abstracts';
    
  public function shouldIncludeField(c:ClassField, owner:Option<ClassType>):Bool
    return Helper.shouldIncludeField(c, owner);
    
  public function drive(type:Type, pos:Position, gen:Type->Position->Expr):Expr
    return 
      switch type.reduce() {
        case TDynamic(null): 
          macro @:pos(pos) this.parseDynamic();
        case TEnum(_.get().module => 'tink.json.Value', _): 
          macro @:pos(pos) this.parseValue();
        case TAbstract(_.get().module => 'tink.json.Serialized', _): 
          macro @:pos(pos) this.parseSerialized();
        case v:
          switch type.getMeta().filter(function (m) return m.has(':jsonParse')) {
            case []: gen(type, pos);
            case v: 
              switch v[0].extract(':jsonParse')[0] {
                case { params: [parser] }: 
                  
                  var path = parser.toString().asTypePath();

                  var rep = 
                    switch (macro @:pos(parser.pos) new $path(null).parse).typeof().sure().reduce() {
                      case TFun([{ t: t }], ret): t;
                      default: parser.reject('field `parse` has wrong signature');
                    }
                  macro @:pos(parser.pos) this.plugins.get($parser).parse(${drive(rep, pos, gen)});
                case v: v.pos.error('@:jsonParse must have exactly one parameter');
              }
          }
        }

}


private typedef LiteInfo = {
  name:String,
  pos:Position,
  type:Type,
  optional:Bool
}
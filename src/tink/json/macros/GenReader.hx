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

class GenReader {
  static public var inst = new GenReader();
  
  function new() {}
  static var OPTIONAL:Metadata = [{ name: ':optional', params:[], pos: (macro null).pos }];
  
  public function wrap(placeholder:Expr, ct:ComplexType):Function
    return placeholder.func(ct);
        
  public function nullable(e) 
    return macro 
      if (this.allow('null')) null;
      else $e;
    
  public function string() 
    return macro (this.parseString().toString() : String);
    
  public function int() 
    return macro this.parseNumber().toInt();
    
  public function float() 
    return macro this.parseNumber().toFloat();
    
  public function bool() 
    return macro this.parseBool();
    
  public function date() 
    return macro Date.fromTime(this.parseNumber().toFloat());
    
  public function bytes() 
    return macro haxe.crypto.Base64.decode(this.parseString().toString());
    
  public function map(k, v)               
    return macro {
      this.expect('[');
      var __ret = new Map();
      if (!allow(']')) {
        do {
          this.expect('[');
          __ret[$k] = this.expect(',') & $v;
          this.expect(']');
        } while (allow(','));
        expect(']');
      }    
      __ret;
    }
    
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
          
          $i{name} = ${f.expr};
            
          ${
            if (optional) macro $b{[]}
            else macro $i{hasName} = true
          }
        } 
        else $read;

      obj.push({
        field: f.name,
        expr: 
          if (optional) macro $i{name}
          else macro if ($i{hasName}) $i{name} else __missing__($v{jsonName}),
      });

      if (optional) 
        vars.push({
          name: name,
          expr: macro null,
          type: macro : Null<$ct>
        })
      else {

        var valType = 
          switch Crawler.plainAbstract(f.type) {
            case Some(a): a;
            default: f.type;
          }       

        vars.push({
          name: name,
          expr: switch valType.getID() {
            case 'Bool': macro false;
            case 'Int': macro 0;
            case 'Float': macro .0;
            default: macro null;
          },
          type: ct,
        });

        vars.push({
          type: macro : Bool,
          name: hasName,
          expr: macro false,
        });
      }
      
    };
        
    return macro {
      
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

      (${EObjectDecl(obj).at()} : $ct);
    };
  }  
  
  public function array(e) 
    return macro {
      this.expect('[');
      var __ret = [];
      if (!allow(']')) {
        do {
          __ret.push($e);
        } while (allow(','));
        expect(']');
      }    
      __ret;
    }
    
  public function enm(constructors:Array<EnumConstructor>, ct, pos:Position, gen:GenType) {
    var fields = new Map<String, LiteInfo>(),
        cases = new Array<Case>();
        
    function captured(f:String)
      return macro @:pos(pos) $i{
        if (f.charAt(0).toUpperCase() == f.charAt(0)) '__'+f.toLowerCase()
        else f
      };      
      
    function mkOpt(f:FieldInfo):FieldInfo
      return
        if (f.optional) f;
        else {
          name: f.name,
          optional: true,
          type: f.type,
          meta: f.meta,
          expr: f.expr,
          pos: f.pos,
        } 
        
    function add(f:LiteInfo) 
      switch fields[f.name] {
        case null: fields[f.name] = f;
        case same if (Crawler.typesEqual(same.type, f.type)):
          fields[f.name] = {
            pos: f.pos,
            name: f.name,
            type: f.type,
            optional: same.optional || f.optional,
          }
        case other: 
          pos.error('conflict for field ${f.name}');
      }        
      
    function mkComplex(fields:Iterable<LiteInfo>):ComplexType
      return TAnonymous([for (f in fields) {
        name: f.name,
        pos: f.pos,
        meta: if (f.optional) OPTIONAL else [],
        kind: FVar(f.type.toComplex()),
      }]);
    var argLess = [];  
    for (c in constructors) {
      
      var inlined = c.inlined,
          cfields = c.fields,
          c = c.ctor,
          name = c.name;

      if (c.type.reduce().match(TEnum(_,_))) 
        argLess.push(new Named(name, Macro.nameNiladic(c)));
      else switch c.meta.extract(':json') {
        case []:
          
          add({
            name: name,
            optional: true,
            type: mkComplex(cfields).toType().sure(),
            pos: c.pos,
          });
          
          cases.push({
            values: [macro { $name : o }],
            guard: macro o != null,
            expr: {
              var args = if (inlined) [macro o];
              else [for (f in cfields) {
                var name = f.name;
                macro o.$name;
              }];
              
              switch args {
                case []: macro ($i{name} : $ct);
                case _: macro ($i{name}($a{args}) : $ct);
              }
            }
          });

        case [{ params:[{ expr: EObjectDecl(obj) }] }]:
          
          var pat = obj.copy(),
              guard = macro true;
            
          for (f in cfields) {
            add(mkOpt(f));
            if (!f.optional)
              guard = macro $guard && ${captured(f.name)} != null;
            
            pat.push({ field: f.name, expr: macro ${captured(f.name)}});
          }
          
          var args = 
            if (inlined) [EObjectDecl([for (f in cfields) { field: f.name, expr: macro ${captured(f.name)} }]).at(pos)];
            else [for (f in cfields) macro ${captured(f.name)}];
          
          var call = switch args {
            case []: macro ($i{name} : $ct);
            case _: macro ($i{name}($a{args}) : $ct);
          }
          
          cases.push({
            values: [EObjectDecl(pat).at()],
            guard: guard,
            expr: call
          });
          
          for (f in obj)
            add({
              pos: f.expr.pos,
              name: f.field, 
              type: f.expr.typeof().sure(),
              optional: true,
            });
          
        case v:
          c.pos.error('invalid use of @:json');
      }      
    }
      
    var ret = macro {
      var __ret = ${gen(mkComplex(fields).toType().sure(), pos)};
      ${ESwitch(
        macro __ret, 
        cases, 
        macro throw new tink.core.Error(422, 'Cannot process '+Std.string(__ret))
      ).at(pos)};
    }

    return
      if (argLess.length == 0) ret;
      else {
        
        var argLessSwitch = ESwitch(macro parseRestOfString().toString(), [for (a in argLess) {
          values: [macro $v{a.value}], expr: macro $i{a.name},
        }].concat([{
          values: [macro invalid], expr: macro throw new tink.core.Error(422, 'Invalid constructor '+invalid),
        }]), null).at(pos);

        macro if (allow('"')) $argLessSwitch else $ret;
      }
  }
  
  public function enumAbstract(names:Array<String>, e:Expr):Expr {
    throw 'not implemented';
  }
  
  public function dyn(e, ct) 
    return macro ($e : Dynamic<$ct>);
    
  public function dynAccess(e)
    return macro {
      this.expect('{');
      var __ret = new haxe.DynamicAccess();
      if (!allow('}')) {
        do {
          __ret[this.parseString().toString()] = expect(':') & $e;
        } while (allow(','));
        expect('}');
      }    
      __ret;
    }
    
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
      switch type.getMeta().filter(function (m) return m.has(':jsonParse')) {
        case []: gen(type, pos);
        case v: 
          switch v[0].extract(':jsonParse')[0] {
            case { params: [parser] }: 
              
              var path = parser.toString().asTypePath();

              var rep = (macro @:pos(parser.pos) {
                var p = new $path(null);
                var x = null;
                p.parse(x);
                x;
              }).typeof().sure();
              macro @:pos(parser.pos) this.plugins.get($parser).parse(${gen(rep, pos)});
            case v: v.pos.error('@:jsonParse must have exactly one parameter');
          }
      }
}


private typedef LiteInfo = {
  name:String,
  pos:Position,
  type:Type,
  optional:Bool
}
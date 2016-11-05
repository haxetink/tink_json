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

class GenReader {
  static var OPTIONAL:Metadata = [{ name: ':optional', params:[], pos: (macro null).pos }];
  
  static public function wrap(placeholder:Expr, ct:ComplexType):Function
    return placeholder.func(ct);
        
  static public function nullable(e) 
    return macro 
      if (this.allow('null')) null;
      else $e;
    
  static public function string() 
    return macro (this.parseString().toString() : String);
    
  static public function int() 
    return macro this.parseNumber().toInt();
    
  static public function float() 
    return macro this.parseNumber().toFloat();
    
  static public function bool() 
    return macro this.parseBool();
    
  static public function date() 
    return macro Date.fromTime(this.parseNumber().toFloat());
    
  static public function bytes() 
    return macro haxe.crypto.Base64.decode(this.parseString().toString());
    
  static public function map(k, v)               
    return macro {
      this.expect('[');
      var __ret = new Map();
      if (!allow(']')) {
        do {
          this.expect('[');
          __ret[$k] = this.expect(',') + $v;
          this.expect(']');
        } while (allow(','));
        expect(']');
      }    
      __ret;
    }
    
  static public function anon(fields:Array<FieldInfo>, ct) {
    
    var read = macro this.skipValue(),
        vars:Array<Var> = [],
        obj:Array<{ field:String, expr:Expr }> = [],
        checks = [];
        
    for (f in fields) {
      var ct = f.type.reduce().toComplex(),
          name = f.name,
          jsonName = switch f.meta.filter(function (m) return m.name == ':json') {
            case []: f.name;
            case [{ params: [name] }]: name.getName().sure();
            case [v]: v.pos.error('@:json must have exactly one parameter');
            case v: v[1].pos.error('duplicate @:json metadata not allowed on a single field');
          },
          optional = f.optional;
         
      read = macro @:pos(f.pos) 
        if (__name__ == $v{jsonName}) {
          @:privateAccess (__ret.$name = ${f.expr});
          ${
            if (optional) macro $b{[]}
            else macro $i{name} = true
          }
        } 
        else $read;
      
      if (!optional) {
        var valType = 
          switch Crawler.plainAbstract(f.type) {
            case Some(a): a;
            default: f.type;
          }
          
        obj.push({
          field: name,
          expr: switch valType.getID() {
            case 'Bool': macro false;
            case 'Int': macro 0;
            case 'Float': macro .0;
            default: macro null;
          },
        });
        vars.push({
          type: macro : Bool,
          name: name,
          expr: macro false,
        });
        checks.push(macro if (!$i{name})  __missing__($v{jsonName}));
      }
      
    };
        
    return macro {
      
      ${EVars(vars).at()};
      var __ret:$ct = ${EObjectDecl(obj).at()};
      
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
      }
      
      $b{checks};
      __ret;
    };
  }  
  
  static public function array(e) 
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
    
  static public function enm(constructors:Array<EnumConstructor>, ct, pos:Position, gen:GenType) {
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
      
    for (c in constructors) {
      
      var inlined = c.inlined,
          cfields = c.fields,
          c = c.ctor,
          name = c.name;
          
      switch c.meta.extract(':json') {
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
              macro ($i{name}($a{args}) : $ct);
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
          
          var call = macro ($i{name}($a{args}) : $ct);
          
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
      
    return macro {
      var __ret = ${gen(mkComplex(fields).toType().sure(), pos)};
      ${ESwitch(
        macro __ret, 
        cases, 
        macro throw new tink.core.Error('Cannot process '+Std.string(__ret))
      ).at(pos)};
    }
  }
  
  static public function dyn(e, ct) 
    return macro ($e : Dynamic<$ct>);
    
  static public function dynAccess(e)
    return macro {
      this.expect('{');
      var __ret = new haxe.DynamicAccess();
      if (!allow('}')) {
        do {
          __ret[this.parseString().toString()] = expect(':') + $e;
        } while (allow(','));
        expect('}');
      }    
      __ret;
    }
    
  static public function rescue(t:Type, pos:Position, gen:GenType) 
    return switch Macro.getRepresentation(t, pos) {
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
    
  static public function reject(t:Type) 
    return 'Cannot parse ${t.toString()}';
}


private typedef LiteInfo = {
  name:String,
  pos:Position,
  type:Type,
  optional:Bool
}
package tink.json.macros;

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.ds.Option;

using haxe.macro.Tools;
using tink.MacroApi;

class Crawler { 
  
  var ret:Array<Field>;
  var gen:Generator;
  var anons:Map<String, Type>;
  
  static public function crawl(type:Type, pos:Position, gen) {
    var c = new Crawler(gen, type, pos);
    
    var expr = c.genType(type, pos);
    
    return {
      expr: expr,
      fields: c.ret,
    }
  }
  
  function new(gen, type:Type, pos:Position) {
    this.gen = gen;
    ret = [];
    anons = new Map();
    
  }  
    
  function add(a:Array<Field>)
    ret = ret.concat(a);
  
  function genType(t:Type, pos:Position):Expr 
    return
      if (t.getID(false) == 'Null')
        gen.nullable(genType(t.reduce(), pos));
      else
        switch t.reduce() {
          
          case _.getID() => 'String': 
            gen.string();
            
          case _.getID() => 'Float': 
            gen.float();
            
          case _.getID() => 'Int': 
            gen.int();
            
          case _.getID() => 'Bool': 
            gen.bool();
            
          case _.getID() => 'Date':
            gen.date();
            
          case _.getID() => 'haxe.io.Bytes':
            gen.bytes();
           
          case TAnonymous(fields):
            
            var method = null;
            
            for (func in anons.keys()) {
              
              var known = anons[func];
              
              if (typesEqual(t, known)) {
                method = func;
                break;
              }
              
            }
            
            if (method == null) {
              method = 'anon${Lambda.count(anons)}';
              
              anons[method] = t;
              
              var ct = t.toComplex();
              
              add([{
                name: method,
                pos: pos,
                kind: FFun(gen.anon(serializableFields(fields.get().fields), ct)),
              }]);
              //add(gen.anon(fields.get().fields, t.toComplex()));
              
            }
            
            var args = [for (s in gen.args()) s.resolve()];
            macro this.$method($a{args});
            
          case TInst(_.get() => { name: 'Array', pack: [] }, [t]):
            
            gen.array(genType(t, pos));
          
          case TDynamic(t):
            
            gen.dyn(gen.dynAccess(genType(t, pos)), t.toComplex());
          
          case TAbstract(_.get() => { name: 'DynamicAccess', pack: ['haxe'] }, [t]):
            
            gen.dynAccess(genType(t, pos));
            
          case TAbstract(_.get() => { name: 'Map', pack: [] }, [k, v]):
            
            gen.map(genType(k, pos), genType(v, pos));
            
          case plainAbstract(_) => Some(a):
            
            genType(a, pos);              
            
          case TEnum(_.get() => e, params):
            
            var constructors = [];
            
            for (name in e.names) {
              
              var c = e.constructs[name],
                  inlined = false;
                  
              var cfields = 
                switch c.type.applyTypeParameters(e.params, params).reduce() {
                  case TFun([{ name: name, t: TAnonymous(anon) }], ret) if (name.toLowerCase() == c.name.toLowerCase()):
                    inlined = true;
                    [for (f in anon.get().fields) { 
                      name: f.name, 
                      type: f.type, 
                      expr: genType(f.type, f.pos),
                      optional: f.meta.has(':optional'), 
                      pos: f.pos 
                    }];
                  case TFun(args, ret):
                    [for (a in args) { 
                      name: a.name, 
                      type: a.t, 
                      expr: genType(a.t, c.pos), 
                      optional: a.opt, 
                      pos: c.pos 
                    }];
                  default:
                    c.pos.error('constructor has no arguments');
                }
              
              constructors.push({
                inlined: inlined,
                fields: cfields,
              });
            }
            
            gen.enm(constructors, t.toComplex());
            
          case v: 
            pos.error(gen.reject(t));
        }
        
  function serializableFields(fields:Array<ClassField>):Array<FieldInfo> {
    
    var ret = new Array<FieldInfo>();
    
    function add(f:ClassField)
      ret.push({
        name: f.name,
        pos: f.pos,
        type: f.type,
        optional: f.meta.has(':optional'),
        expr: genType(f.type, f.pos),
      });
      
    for (f in fields)
      if (!f.meta.has(':transient'))
        switch f.kind {
          case FVar(AccNever | AccCall, AccNever | AccCall):
            if (f.meta.has(':isVar'))
              add(f);
          case FVar(read, write):
            add(f);
          default:
        }
    return ret;
  }
  
  static function typesEquivalent(t1, t2)
    return Context.unify(t1, t2) && Context.unify(t2, t1);

  static function typesEqual(t1, t2)
    return typesEquivalent(t1, t2);//TODO: make this more exact
  
  static function plainAbstract(t:Type)
    return switch t.reduce() {
      case TAbstract(_.get() => a, params):
        function apply(t:Type)
          return t.applyTypeParameters(a.params, params);
        
        var ret = apply(a.type);
        
        function get(casts:Array<{t:Type, field:Null<ClassField>}>) {
          for (c in casts)
            if (c.field == null && typesEqual(ret, apply(c.t))) 
              return true;
          return false;
        }        
        
        if (get(a.from) && get(a.to)) Some(ret) else None;
       
      default: None;
    }  
    
}
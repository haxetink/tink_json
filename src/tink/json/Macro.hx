package tink.json;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;
using tink.MacroApi;

class Macro {
  
  static public function build():Type
    return 
      switch Context.getLocalType() {
        case TInst(_.toString() => 'tink.json.Parser', [v]):
          parserForType(v);
        default:
          throw 'assert';
      }    
  static var counter = 0;
  static function parserForType(t:Type):Type {
    
    var name = 'JsonParser${counter++}',
        ct = t.toComplex(),
        pos = Context.currentPos();
    
    var cl = macro class $name extends tink.json.Parser.BasicParser {
      public function new() {}
    } 
    
    function add(t:TypeDefinition)
      cl.fields = cl.fields.concat(t.fields);
      
    var anons = new Map<String, Type>();
    
    function parse(t:Type, pos:Position):Expr
      return
        if (t.getID(false) == 'Null')
          macro this.parseNull(function () return ${parse(t.reduce(), pos)});
        else
          switch t.reduce() {
            
            case _.getID() => 'String': 
              macro (this.parseString() : String);
              
            case _.getID() => 'Float': 
              macro Std.parseFloat(this.parseNumber());
              
            case _.getID() => 'Int': 
              macro Std.parseInt(this.parseNumber());
              
            case _.getID() => 'Bool': 
              macro this.parseBool();
              
            case TAnonymous(fields):
              
              var method = null;
              
              for (func in anons.keys()) {
                
                var known = anons[func];
                
                if (Context.unify(t, known) && Context.unify(known, t)) {
                  method = func;
                  break;
                }
                
              }
              
              if (method == null) {
                method = 'parseAnon${Lambda.count(anons)}';
                
                anons[method] = t;
                
                var fields = fields.get().fields,
                    read = macro this.skipValue(),
                    vars:Array<Var> = [],
                    obj:Array<{ field:String, expr:Expr }> = [],
                    optional = [],
                    ct = t.toComplex();
                    
                for (f in fields) {
                  var ct = f.type.reduce().toComplex();
                     
                  read = macro @:pos(f.pos) 
                    if (__name__ == $v{f.name}) 
                      $i{f.name} = tink.core.Ref.to(${parse(f.type, f.pos)})
                    else $read;
                  
                  vars.push({
                    type: macro : Null<tink.core.Ref<$ct>>,
                    name: f.name,
                    expr: macro null,
                  });
                  
                  if (f.meta.has(':optional')) {
                    var name = f.name;
                    optional.push(macro if ($i{f.name} != null) __ret.$name = $i{f.name}.value);
                  }
                  else
                    obj.push({
                      field: f.name,
                      expr: macro if ($i{f.name} == null) __missing__($v{f.name}) else $i{f.name}.value,
                    });
                };
                
                add(macro class {
                  function $method():$ct {
                    ${EVars(vars).at()};
                    var __start__ = this.parseObject(function (__name__) {
                      $read;
                    });
                    function __missing__(field:String):Dynamic {
                      return die('missing ' + field + ' in ' + this.source[__start__...this.pos].toString());
                    }
                    var __ret:$ct = ${EObjectDecl(obj).at()};
                    $b{optional};
                    return __ret;
                  }
                });
              }
              
              macro this.$method();
            case TInst(_.get() => { name: 'Array', pack: [] }, [t]):
              macro this.parseArray(function () return ${parse(t, pos)});
            case v: 
              pos.error('Cannot handle ${t.toString()}');
          }
    
    add(macro class { 
      public function parse(source):tink.core.Outcome < $ct, tink.core.Error > {
        this.init(source);
        return 
          tink.core.Error.catchExceptions(
            function () return ${parse(t, pos)}
          );
      }
    });
        
    Context.defineType(cl);
    
    return Context.getType(name);    
  }
}
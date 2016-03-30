package tink.json;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;
using tink.MacroApi;

class Macro {
  
  static public function buildParser():Type
    return 
      switch Context.getLocalType() {
        case TInst(_.toString() => 'tink.json.Parser', [v]):
          parserForType(v);
        default:
          throw 'assert';
      }    
      
  static var parserCounter = 0;
  static function parserForType(t:Type):Type {
    
    var name = 'JsonParser${parserCounter++}',
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
  
  static public function buildWriter():Type
    return 
      switch Context.getLocalType() {
        case TInst(_.toString() => 'tink.json.Writer', [v]):
          writerForType(v);
        default:
          throw 'assert';
      }    
      
  static var writerCounter = 0;
  static function writerForType(t:Type):Type {
    
    var name = 'JsonWriter${writerCounter++}',
        ct = t.toComplex(),
        pos = Context.currentPos();
    
    var cl = macro class $name extends tink.json.Writer.BasicWriter {
      public function new() {}
    } 
    
    function add(t:TypeDefinition)
      cl.fields = cl.fields.concat(t.fields);
      
    var anons = new Map<String, Type>();
    
    function write(t:Type, pos:Position):Expr 
      return
        if (t.getID(false) == 'Null')
          macro this.writeNull(value, function (value) ${write(t.reduce(), pos)});
        else
          switch t.reduce() {
            
            case _.getID() => 'String': 
              macro this.writeString(value);
              
            case _.getID() => 'Float': 
              macro this.writeFloat(value);
              
            case _.getID() => 'Int': 
              macro this.writeInt(value);
              
            case _.getID() => 'Bool': 
              macro this.writeBool(value);
              
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
                method = 'writeAnon${Lambda.count(anons)}';
                
                anons[method] = t;
                
                var fields = fields.get().fields,
                    ct = t.toComplex();
                
                add(macro class {
                  function $method(value:$ct):Void {
                    var open = '{';
                    $b{[for (f in fields) {
                      var name = f.name;
                      macro {
                        this.output('${if (f == fields[0]) "$open" else ","}"$name":');
                        var value = value.$name;
                        ${write(f.type, f.pos)};
                      }
                    }]};
                    char('}'.code);
                  }
                });
              }
              
              macro this.$method(value);
            case TInst(_.get() => { name: 'Array', pack: [] }, [t]):
              macro this.writeArray(value, function (value) ${write(t, pos)});
            case v: 
              pos.error('Cannot handle ${t.toString()}');
          }

    add(macro class { 
      public function write(value:$ct):String {
        this.init();
        ${write(t, pos)};
        return this.buf.toString();
      }
    });
    
    Context.defineType(cl);
    
    return Context.getType(name);    
  }
  
}
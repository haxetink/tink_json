package tink.json;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;
using tink.MacroApi;

class Macro {
  
  static function getType(name) 
    return 
      switch Context.getLocalType() {
        case TInst(_.toString() == name => true, [v]):
          v;
        default:
          throw 'assert';
      }      
      
  static function typesEqual(t1, t2)
    return Context.unify(t1, t2) && Context.unify(t2, t1);
    
  static public function buildParser():Type
    return parserForType(getType('tink.json.Parser'));
  
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
                
                if (typesEqual(t, known)) {
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
                    checks = [],
                    ct = t.toComplex();
                    
                for (f in fields) {
                  var ct = f.type.reduce().toComplex(),
                      name = f.name,
                      optional = f.meta.has(':optional');
                     
                  read = macro @:pos(f.pos) 
                    if (__name__ == $v{name}) {
                      @:privateAccess (__ret.$name = ${parse(f.type, f.pos)});//in case the field is (default, null) or something
                      ${
                        if (optional) macro $b{[]}
                        else macro $i{name} = true
                      }
                    } 
                    else $read;
                  
                  if (!optional) {
                    obj.push({
                      field: name,
                      expr: switch f.type.getID() {
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
                    checks.push(macro if (!$i{name})  __missing__($v{f.name}));
                  }
                  
                };
                
                add(macro class {
                  function $method():$ct {
                    
                    ${EVars(vars).at()};
                    var __ret:$ct = ${EObjectDecl(obj).at(pos)};
                    
                    var __start__ = this.pos;
                    expect('{');
                    if (!allow('}')) {
                      do {
                        var __name__:tink.parse.StringSlice = this.parseString();
                        expect(':');
                        $read;
                      } while (allow(','));
                      expect('}');
                    }
                      
                    function __missing__(field:String):Dynamic {
                      return die('missing ' + field + ' in ' + this.source[__start__...this.pos].toString());
                    }
                    
                    $b{checks};
                    return __ret;
                  }
                });
              }
              
              macro this.$method();
            case TInst(_.get() => { name: 'Array', pack: [] }, [t]):
              macro {
                this.expect('[');
                var __ret = [];
                if (!allow(']')) {
                  do {
                    __ret.push(${parse(t, pos)});
                  } while (allow(','));
                  expect(']');
                }    
                __ret;
              }
              
            case TAbstract(_.get() => { name: 'Map', pack: [] }, [k, v]):
              macro {
                this.expect('[');
                var __ret = new Map();
                if (!allow(']')) {
                  do {
                    this.expect('[');
                    __ret[${parse(k, pos)}] = this.expect(',') + ${parse(v, pos)};
                    this.expect(']');
                  } while (allow(','));
                  expect(']');
                }    
                __ret;
              }
            
            case TDynamic(t):
              var ct = t.toComplex();
              macro (${parse((macro : haxe.DynamicAccess<$ct>).toType().sure(), pos)} : Dynamic<$ct>);
            case TAbstract(_.get() => { name: 'DynamicAccess', pack: ['haxe'] }, [t]):
              var ct = t.toComplex();
              macro {
                this.expect('{');
                var __ret = new haxe.DynamicAccess();
                if (!allow('}')) {
                  do {
                    __ret[this.parseString().toString()] = expect(':') + ${parse(t, pos)};
                  } while (allow(','));
                  expect('}');
                }    
                __ret;
                
              }
              
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
    return writerForType(getType('tink.json.Writer'));
      
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
                
                if (typesEqual(t, known)) {
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
              
              macro {
                this.char('['.code);
                var first = true;
                for (value in value) {
                  if (first)
                    first = false;
                  else
                    this.char(','.code);
                  ${write(t, pos)}
                }
                this.char(']'.code);  
              }
              
            case TDynamic(t):
              
              var ct = t.toComplex();
              macro {
                var value:haxe.DynamicAccess<$ct> = value;
                ${write((macro : haxe.DynamicAccess<$ct>).toType().sure(), pos)};
              }
            
            case TAbstract(_.get() => ({ name: 'DynamicAccess', pack: ['haxe'] } | { name: 'Dynamic', pack: [] }), [t]):
              var ct = t.toComplex();
              macro {
                var value:haxe.DynamicAccess<$ct> = value,
                    first = true;
                    
                this.char('{'.code);
                for (k in value.keys()) {
                  if (first)
                    first = false;
                  else
                    this.char(','.code);
                    
                  this.writeString(k);
                  this.char(':'.code);
                  {
                    var value = value.get(k);
                    ${write(t, pos)}
                  }
                  
                }
                this.char('}'.code);
              }
            case TAbstract(_.get() => { name: 'Map', pack: [] }, [k, v]):
              macro {
                this.char('['.code);
                var first = true;
                for (k in value.keys()) {
                  if (first)
                    first = false;
                  else
                    this.char(','.code);
                  this.char('['.code);
                  {
                    var value = k;
                    ${write(k, pos)}
                  }
                  this.char(','.code);
                  {
                    var value = value.get(k);
                    ${write(v, pos)}
                  }
                  
                  this.char(']'.code);
                }
                this.char(']'.code);  
              }
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
package tink.json;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.ds.Option;
import tink.typecrawler.Crawler;
import tink.json.macros.GenReader;
import tink.json.macros.GenWriter;

using haxe.macro.Tools;
using tink.MacroApi;

private typedef FieldInfo = {
  name:String,
  pos:Position,
  type:Type,
  optional:Bool
}

class Macro {
    
  static function getType(name) 
    return 
      switch Context.getLocalType() {
        case TInst(_.toString() == name => true, [v]):
          v;
        default:
          throw 'assert';
      }      

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
      
    var ret = Crawler.crawl(t, pos, GenReader);
    
    cl.fields = cl.fields.concat(ret.fields);  
    
    add(macro class { 
      public function parse(source):$ct @:pos(ret.expr.pos) {
        this.init(source);
        return ${ret.expr};
      }
      public function tryParse(source)
        return tink.core.Error.catchExceptions(function () return parse(source));
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
    
    var ret = Crawler.crawl(t, pos, GenWriter);
    
    cl.fields = cl.fields.concat(ret.fields);
    
    function add(t:TypeDefinition)
      cl.fields = cl.fields.concat(t.fields);

    add(macro class { 
      public function write(value:$ct):String {
        this.init();
        ${ret.expr};
        return this.buf.toString();
      }
    });
    
    Context.defineType(cl);
    
    return Context.getType(name);    
  }
  
}

@:forward
private abstract HasName(String) from String to String {
  @:from static function fieldInfo(f:FieldInfo):HasName
    return f.name;
}
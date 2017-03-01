package tink.json.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.ds.Option;
import tink.macro.BuildCache;

import tink.typecrawler.*;

using haxe.macro.Tools;
using tink.MacroApi;

class Macro {
    
  static public function nativeName(f:FieldInfo)
    return
      switch f.meta.filter(function (m) return m.name == ':json') {
        case []: f.name;
        case [{ params: [name] }]: name.getName().sure();
        case [v]: v.pos.error('@:json must have exactly one parameter');
        case v: v[1].pos.error('duplicate @:json metadata not allowed on a single field');
      }    
  
  static function getType(name) 
    return 
      switch Context.getLocalType() {
        case TInst(_.toString() == name => true, [v]):
          v;
        default:
          throw 'assert';
      }      

  static public function buildParser():Type
    return BuildCache.getType('tink.json.Parser', parser);
    
  static function parser(ctx:BuildContext):TypeDefinition {
    var name = ctx.name,
        ct = ctx.type.toComplex();
        
    var cl = macro class $name extends tink.json.Parser.BasicParser {
      public function new() {}
    } 
    
    function add(t:TypeDefinition)
      cl.fields = cl.fields.concat(t.fields);
      
    var ret = Crawler.crawl(ctx.type, ctx.pos, GenReader.inst);
    
    cl.fields = cl.fields.concat(ret.fields);  
    
    add(macro class { 
      public function parse(source):$ct @:pos(ret.expr.pos) {
        this.init(source);
        return ${ret.expr};
      }
      public function tryParse(source)
        return tink.core.Error.catchExceptions(function () return parse(source));
    });
    
    return cl;
  }
    
  static public function buildWriter():Type
    return BuildCache.getType('tink.json.Writer', writer);
      
  static function writer(ctx:BuildContext):TypeDefinition {
    var name = ctx.name,
        ct = ctx.type.toComplex();
    
    var cl = macro class $name extends tink.json.Writer.BasicWriter {
      public function new() {}
    } 
    
    var ret = Crawler.crawl(ctx.type, ctx.pos, GenWriter);
    
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
    
    return cl;
  }
  
  static public function getRepresentation(t:Type, pos:Position) {

    switch t.reduce() {
      case TDynamic(null) | TMono(_): return None;
      default: 
    }
    var ct = t.toComplex({ direct: true });
    
    return
      switch (macro tink.json.Representation.of((null : $ct)).get()).typeof() {
        case Success(rep):
          
          var rt = rep.toComplex();
          
          if (!(macro ((null : tink.json.Representation<$rt>) : $ct)).typeof().isSuccess()) 
            pos.error('Cannot represent ${t.toString()} in JSON because ${(macro : tink.json.Representation<$rt>).toString()} cannot be converted to ${t.toString()}');
          
          Some(rep);
          
        default:
          None;
      }
  }
  
  static public function shouldSerialize(f:ClassField) 
    return 
      !f.meta.has(':transient') 
      && switch f.kind {
        case FVar(AccNever | AccCall, AccNever | AccCall):
          f.meta.has(':isVar');
        case FVar(_, _): true;
        default: false;
      }  
}

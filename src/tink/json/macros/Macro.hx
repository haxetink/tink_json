package tink.json.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.ds.Option;
import tink.macro.BuildCache;

import tink.typecrawler.*;

using haxe.macro.Tools;
using StringTools;
using tink.MacroApi;

class Macro {
  
  static function compact(?prefix:String = '', ?fields:Array<Field>) {
    #if tink_json_compact_code
    if (fields == null)
      fields = Context.getBuildFields();
    for (i in 0...fields.length) {
      var f = fields[i];

      var meta = {
        name: ':native',
        params: [macro $v{prefix + i.shortIdent()}],
        pos: f.pos,
      }
      switch f.meta {
        case null: f.meta = [meta];
        case v: v.push(meta);
      }
    }      
    return fields;
    #else
    return null;
    #end
  }
    
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

  static public function nameNiladic(c:EnumField)
    return
      switch c.meta.extract(':json') {
        case []: c.name;
        case [{ params:[{ expr: EConst(CString(v)) }]}]: v;
        case v: c.pos.error('invalid use of @:json');
      }
  

  static function parser(ctx:BuildContext):TypeDefinition {
    var name = ctx.name,
        ct = ctx.type.toComplex();
        
    var cl = macro class $name extends tink.json.Parser.BasicParser {
      public function new() super();
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

    compact('p', cl.fields);
    return cl;
  }

  static public function buildWriter():Type
    return BuildCache.getType('tink.json.Writer', writer);
      
  static function writer(ctx:BuildContext):TypeDefinition {
    var name = ctx.name,
        ct = ctx.type.toComplex();
        
    var cl = macro class $name extends tink.json.Writer.BasicWriter {
      public function new() super();
    } 
    
    var ret = Crawler.crawl(ctx.type, ctx.pos, GenWriter.inst);
    
    cl.fields = cl.fields.concat(ret.fields);
    
    function add(t:TypeDefinition)
      cl.fields = cl.fields.concat(t.fields);
    
    add(macro class { 
      public function write(value:$ct):tink.json.Serialized<$ct> {
        this.init();
        ${ret.expr};
        return cast this.buf.toString();
      }
    });
    compact('w', cl.fields);
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

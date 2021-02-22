package tink.json.schema;

using tink.CoreApi;

#if !macro
@:genericBuild(tink.json.schema.SchemaWriter.build())
class SchemaWriter<T> {}

#else

import haxe.macro.Expr;
import haxe.macro.Type;
import tink.typecrawler.Crawler;
import tink.typecrawler.Generator;
import tink.json.macros.GenSchemaWriter;
import tink.macro.BuildCache;

using tink.MacroApi;

class SchemaWriter {
  
  static public function build(?type, ?pos):Type
    return BuildCache.getType('tink.json.schema.SchemaWriter', (ctx:BuildContext) -> {
      var name = ctx.name,
      ct = ctx.type.toComplex();
  
      var cl = macro class $name {
        public function new() {}
      }
    
      var ret = Crawler.crawl(ctx.type, ctx.pos, crawler -> (new GenSchemaWriter(crawler):Generator));
    
      cl.fields = cl.fields.concat(ret.fields);
    
      function add(t:TypeDefinition)
        cl.fields = cl.fields.concat(t.fields);
    
      add(macro class {
        public function write():tink.json.schema.Schema.SchemaType {
          final const = null;
          return ${ret.expr};
        }
      });
      
      // trace(new haxe.macro.Printer().printTypeDefinition(cl));
      
      return cl;
    }, @:privateAccess tink.json.macros.Macro.normalize);
}

#end
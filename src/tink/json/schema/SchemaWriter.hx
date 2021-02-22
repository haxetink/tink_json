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
      final name = ctx.name,
      ct = ctx.type.toComplex();
  
      final cl = macro class $name {
        public function new() {}
      }
    
      final ret = Crawler.crawl(ctx.type, ctx.pos, crawler -> (new GenSchemaWriter(crawler):Generator));
    
      // TODO: profile this "inline everything" approach
      for(f in ret.fields) switch f.access {
        case null: f.access = [AInline];
        case a: a.push(AInline);
      }
      cl.fields = cl.fields.concat(ret.fields);
    
      function add(t:TypeDefinition)
        cl.fields = cl.fields.concat(t.fields);
    
      add(macro class {
        public inline function write():tink.json.schema.Schema.SchemaType {
          final const = null;
          return ${ret.expr};
        }
      });
      
      // trace(new haxe.macro.Printer().printTypeDefinition(cl));
      
      return cl;
    }, @:privateAccess tink.json.macros.Macro.normalize);
}

#end
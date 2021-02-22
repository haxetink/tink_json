package tink.json.macros;

#if macro
import haxe.ds.Option;
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import tink.typecrawler.FieldInfo;
import tink.typecrawler.Generator;

using haxe.macro.Tools;
using tink.MacroApi;

class GenSchemaWriter extends GenBase {
  
  public function new(crawler) {
    super(':jsonStringify', crawler);
  }

  public function wrap(placeholder:Expr, ct:ComplexType):Function
    return (macro {final const = null; $placeholder;}).func(macro:tink.json.schema.Schema.SchemaType);

  public function nullable(e)
    return macro SNullable($e);

  public function string()
    return macro SPrimitive(PString({const: const}));

  public function int()
    return macro SPrimitive(PInt({const: const}));

  public function float()
    return macro SPrimitive(PFloat({const: const}));

  public function bool()
    return macro SPrimitive(PBool({const: const}));

  public function date()
    return macro SPrimitive(PDate({const: const}));

  public function bytes()
    return macro throw 'TODO';

  public function map(k, v) {
    k = macro {final const = null; $k;}
    v = macro {final const = null; $v;}
    return macro SArray({type: STuple({values: [$k, $v]})});
  }

  public function anon(fields:Array<FieldInfo>, ct) {
	  final fields = fields.map(f -> macro {
			name: $v{f.name},
			type: ${f.expr},
			optional: $v{f.optional},
	  });
	  return macro SObject({fields: $a{fields}});
  }

  public function array(e)
    return macro SArray({type: $e});

  public function enm(constructors:Array<EnumConstructor>, ct:ComplexType, pos:Position, _) {
    
    var types = [];
    for (c in constructors) {
      var nullable = isInlineNullable(c),
          cfields = c.fields,
          inlined = c.inlined,
          c = c.ctor,
          name = c.name;
      types.push(
        if (c.type.reduce().match(TEnum(_,_))) {
          macro {
            final const = $v{name};
            ${string()}
          }
        } else {
          final fields = cfields.map(f -> macro {
            name: $v{f.name},
            type: ${f.expr},
            optional: $v{f.optional},
          });
          macro SObject({fields: [{
            name: $v{name},
            type: SObject({fields: $a{fields}}),
            optional: false,
          }]});
        }
      );
    }
    
    return macro SOneOf({list: $a{types}});
  }

  public function enumAbstract(names:Array<Expr>, e:Expr, ct:ComplexType, pos:Position):Expr {
	return macro throw 'TODO';
    // return macro @:pos(pos) {
    //   var value = cast value;
    //   $e;
    // }
  }

  public function dyn(e, ct)
	return macro throw 'TODO';

  public function dynAccess(e)
	return macro throw 'TODO';

  override public function rescue(t:Type, pos:Position, gen:GenType):Option<Expr>
    return
      switch t.reduce() {

        case TInst(_.get() => { isInterface: true }, _):

          pos.error('[tink_json] ${t.getID()} is an interface and cannot be stringified. ');

        case TInst(_.get() => cl, params):
          //TODO: this should be handled by converting the class to an anonymous type and handing that off to `gen`
          var a = new Array<FieldInfo>();

          for (f in cl.fields.get())
            if (Macro.shouldSerialize(f)) {
              var ft = f.type.applyTypeParameters(cl.params, params);
              a.push(new FieldInfo({ name: f.name, pos: f.pos, type: ft }, gen, false, f.meta.get(), FieldInfo.fieldAccess(f)));
            }

          Some(anon(a, t.toComplex()));

        default:
          super.rescue(t, pos, gen);
      }

  public function reject(t:Type)
    return 'tink_json cannot stringify ${t.toString()}';

  override function processRepresentation(pos:Position, actual:Type, representation:Type, value:Expr):Expr {
    var ct = representation.toComplex();
    return macro @:pos(pos) {
      var value = (value : tink.json.Representation<$ct>).get();
      $value;
    }
  }

  override function processDynamic(pos:Position):Expr
    return macro @:pos(pos) this.writeDynamic(value);

  override function processValue(pos:Position):Expr
    return macro @:pos(pos) this.writeValue(value);

  override function processSerialized(pos:Position):Expr
    return macro @:pos(pos) this.output(value);

  override function processLazy(t, pos)
    return macro @:pos(pos) {
      var v:tink.json.Serialized<$t> = value.get();
      this.output(v);
    }

  override function genCached(id:Int, normal:Expr, type:Type) {
    var map = 'cache$id',
        counter = 'counter$id';
    crawler.add(macro class {
      var $map = new Map();
      var $counter = 0;
    });
    return macro switch ($i{map}[value]) {
      case null:
        $i{map}[value] = $i{counter}++;
        $normal;
      case v: writeInt(v);
    }
  }

  static var aliasCount = 0;
  override function processCustom(c:CustomRule, original:Type, gen:Type->Expr):Expr {
    var original = original.toComplex();
    return switch c {
      case WithClass(path, pos):
        var rep = (macro @:pos(pos) { var f = null; new $path(null).prepare((f():$original)); }).typeof().sure();
        var dotpath = switch path.params {
          case []:
            var tmp = path.pack.concat([path.name]);
            if(path.sub != null) tmp.push(path.sub);
            macro $p{tmp}
          case _: // the type has type parameters
            // because we don't have expr to represent a complex type...
            // so we typedef the type then use its typepath

            var tmp = ['tink', 'json', 'tmpwrite', 'Temp${aliasCount++}'];
            haxe.macro.Context.defineType({
              pos: pos,
              pack: tmp.slice(0, tmp.length - 1),
              name: tmp[tmp.length - 1],
              kind: TDAlias(TPath(path)),
              fields: [],
            });
            macro $p{tmp}
        }

        return macro @:pos(pos) {
          var value = this.plugins.get($dotpath).prepare(value);
          ${gen(rep)};
        }
      case WithFunction(e):
        if (e.expr.match(EFunction(_))) {
          var ret = e.pos.makeBlankType();
          e = macro @:pos(e.pos) ($e:$original->$ret);
        }
        //TODO: the two cases look suspiciously similar
        var rep = (macro @:pos(e.pos) $e((cast null:$original))).typeof().sure();
        return macro @:pos(e.pos) {
          var value = $e(value);
          ${gen(rep)};
        }
    }
  }

  override public function drive(type:Type, pos:Position, gen:GenType):Expr
    return
      switch type.reduce() {
        case TAbstract(_.get() => {pack: ['haxe', 'ds'], name: 'Vector'}, [t]):
          this.array(gen(t, pos));
        case TAbstract(_.get() => {pack: [], name: 'UInt'}, _):
          macro @:pos(pos) {
            var v = Std.string((value:Float));
            ${if(haxe.macro.Context.defined('lua')) macro v = v.split('.')[0] else macro null}
            ${if(haxe.macro.Context.defined('java')) macro v = this.expandScientificNotation(v) else macro null}
            this.output(v);
          }
        case TEnum(_.get().module => 'haxe.ds.Either', [left, right]):
          var lct = left.toComplex();
          var rct = right.toComplex();
          macro @:pos(pos) switch value {
            case Left(v): this.output(tink.Json.stringify((v:$lct)));
            case Right(v): this.output(tink.Json.stringify((v:$rct)));
          }
        default: super.drive(type, pos, gen);
      }
}
#end
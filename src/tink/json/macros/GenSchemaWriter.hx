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

  var anonCounter = 0;
  var pending:Null<Type>; // the type most recently passed to drive(), i.e. the one being cached when wrap() runs

  public function new(crawler) {
    super(':jsonStringify', crawler);
  }

  function makeId(ct:ComplexType) {
    final raw = switch ct {
      // private types can't be expressed as a type path and yield an opaque marker
      case TPath({pack: ['tink', 'macro'], name: 'DirectType'}): typeId();
      case TPath(_): ct.toString();
      default: typeId();
    }
    // sanitized so it can appear in a JSON pointer without escaping
    return ~/[^A-Za-z0-9_.]/g.replace(raw, '_');
  }

  function typeId()
    return switch pending {
      case TEnum(_, _) | TInst(_, _) | TAbstract(_, _): pending.toString();
      default: 'Anon${anonCounter++}';
    }

  public function wrap(placeholder:Expr, ct:ComplexType):Function {
    final id = makeId(ct);
    // every crawled type is registered under its id, so the output can
    // reference it via $defs/$ref and recursive types terminate
    return (macro {
      if (!this.defs.exists($v{id})) {
        this.defs.set($v{id}, SAny); // placeholder to stop recursion
        this.defs.set($v{id}, $placeholder);
      }
      SRef($v{id});
    }).func(macro:tink.json.schema.Schema.SchemaType);
  }

  public function nullable(e)
    return macro SNullable($e);

  public function string()
    return macro SPrimitive(PString(null));

  public function int()
    return macro SPrimitive(PInt(null));

  public function float()
    return macro SPrimitive(PFloat(null));

  public function bool()
    return macro SPrimitive(PBool(null));

  public function date()
    return macro SPrimitive(PDate);

  public function bytes() {
    // built at macro time because EReg.escape is target-dependent
    final pattern = '^[${EReg.escape(haxe.crypto.Base64.CHARS + '=')}]*$';
    return macro SPrimitive(PRegex($v{pattern}));
  }

  public function map(k, v)
    return macro SArray(STuple([$k, $v]));

  function objectFields(fields:Array<FieldInfo>):Expr {
    final resolved = fields.map(f -> {
      var optional = f.optional,
          expr = f.expr;
      switch f.type.reduce() {
        // Option<T> fields are written as plain T and omitted when None
        case TEnum(_.get() => {name: 'Option', pack: ['haxe', 'ds']}, [t]):
          optional = true;
          expr = f.as(t);
        default:
      }
      {name: Macro.nativeName(f), optional: optional, expr: expr}
    });
    resolved.sort((a, b) -> switch [a.optional, b.optional] {
      case [false, true]: -1;
      case [true, false]: 1;
      case _: Reflect.compare(a.name, b.name);
    });
    return macro $a{resolved.map(f -> macro {
      name: $v{f.name},
      type: ${f.expr},
      optional: $v{f.optional},
    })};
  }

  public function anon(fields:Array<FieldInfo>, ct)
    return macro SObject(${objectFields(fields)});

  public function array(e)
    return macro SArray($e);

  public function enm(constructors:Array<EnumConstructor>, ct:ComplexType, pos:Position, _) {
    if (constructors.length == 0) pos.error('Enum ${ct.toString()} has no constructors and tink_json can\'t handle it');

    final enumTags = Macro.enumLevelTag(ct, pos);
    Macro.requireObjectTaggedCtors(enumTags, constructors, pos);

    var types = [];
    for (c in constructors) {
      var nullable = isInlineNullable(c),
          cfields = c.fields,
          ctor = c.ctor,
          name = ctor.name;
      types.push(
        if (ctor.type.reduce().match(TEnum(_,_)))
          switch Macro.extractObjectJsonTag(ctor.meta) {
            case null:
              switch ctor.meta.extract(':json') {
                case []:
                  macro SPrimitive(PString($v{name}));
                case [{ params: [{ expr: EConst(CString(v)) }] }]:
                  macro SPrimitive(PString($v{v}));
                case _:
                  ctor.pos.error('invalid use of @:json');
              }
            case ctorTags:
              final merged = Macro.mergeTags(enumTags, ctorTags, ctor.pos);
              Macro.validatePresentTags(merged, cfields, ctor.pos);
              // niladic object tag: only const fields (presents already rejected)
              macro SConst($v{Macro.constTagValues(merged)});
          }
        else
          switch ctor.meta.extract(':json') {
            case []:
              var inner = macro SObject(${objectFields(cfields)});
              if (nullable)
                inner = macro SNullable($inner);
              macro SObject([{
                name: $v{name},
                type: $inner,
                optional: false,
              }]);

            case [{ params: [{ expr: EConst(CString(jsonKey)) }] }]:
              var inner = macro SObject(${objectFields(cfields)});
              if (nullable)
                inner = macro SNullable($inner);
              macro SObject([{
                name: $v{jsonKey},
                type: $inner,
                optional: false,
              }]);

            case _ if (nullable):
              ctor.pos.error('@:json cannot be nullable');

            case [{ params: [{ expr: EObjectDecl(_) }] }]:
              final ctorTags = Macro.extractObjectJsonTag(ctor.meta);
              final merged = Macro.mergeTags(enumTags, ctorTags, ctor.pos);
              Macro.validatePresentTags(merged, cfields, ctor.pos);
              final byName = [for (f in cfields) f.name => f];
              final tagFields = [];
              final seen = new Map<String, Bool>();
              for (t in merged) switch t {
                case Const(fname, value):
                  tagFields.push(macro {
                    name: $v{fname},
                    type: tink.json.schema.Schema.SchemaType.SConst($v{Macro.getExprValue(value)}),
                    optional: false,
                  });
                  seen[fname] = true;
                case Present(fname, _):
                  final f = byName[fname];
                  tagFields.push(macro {
                    name: $v{fname},
                    type: ${f.expr},
                    optional: false,
                  });
                  seen[fname] = true;
              }
              final rest = [for (f in cfields) if (!seen.exists(f.name)) f];
              macro SObject((${macro $a{tagFields}}:Array<tink.json.schema.Schema.ObjectFieldSchema>).concat(${objectFields(rest)}));

            default:
              ctor.pos.error('invalid use of @:json');
          }
      );
    }

    return macro SOneOf(${macro $a{types}});
  }

  public function enumAbstract(names:Array<Expr>, e:Expr, ct:ComplexType, pos:Position):Expr {
    return macro SEnum(${macro cast $a{names}});
  }

  public function dyn(e, ct)
    return e;

  public function dynAccess(e)
    return macro SDynamicAccess($e);

  override public function rescue(t:Type, pos:Position, gen:GenType):Option<Expr>
    return
      switch t.reduce() {

        case TInst(_.get() => { isInterface: true }, _):

          pos.error('[tink_json] ${t.getID()} is an interface and cannot be stringified. ');

        case TInst(_.get() => cl, params):
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
    return 'tink_json cannot generate a schema for ${t.toString()}';

  override function processRepresentation(pos:Position, actual:Type, representation:Type, value:Expr):Expr
    return value;

  override function processDynamic(pos:Position):Expr
    return macro @:pos(pos) SAny;

  override function processValue(pos:Position):Expr
    return macro @:pos(pos) SAny;

  // Serialized/Lazy are intercepted in drive() below where the type parameter
  // is still available; these fallbacks are unreachable
  override function processSerialized(pos:Position):Expr
    return macro @:pos(pos) SAny;

  override function processLazy(t, pos)
    return macro @:pos(pos) SAny;

  override function genCached(id:Int, normal:Expr, type:Type)
    // Cached<T> is written either in full or as an integer backreference
    return macro SOneOf([$normal, SPrimitive(PInt(null))]);

  override function processCustom(c:CustomRule, original:Type, gen:Type->Expr):Expr {
    var original = original.toComplex();
    return switch c {
      case WithClass(path, pos):
        var rep = (macro @:pos(pos) { var f = null; new $path(null).prepare((f():$original)); }).typeof().sure();
        gen(rep);
      case WithFunction(e):
        if (e.expr.match(EFunction(_))) {
          var ret = e.pos.makeBlankType();
          e = macro @:pos(e.pos) ($e:$original->$ret);
        }
        var rep = (macro @:pos(e.pos) $e((cast null:$original))).typeof().sure();
        gen(rep);
    }
  }

  override public function drive(type:Type, pos:Position, gen:GenType):Expr {
    pending = type.reduce();
    return
      switch type.reduce() {
        // Context.getType('Dynamic') yields TDynamic(TMono); treat it as plain Dynamic
        case TDynamic(t) if (t != null && t.match(TMono(_))):
          macro @:pos(pos) SAny;
        case TAbstract(_.get() => {pack: ['tink', 'core'], name: 'Pair'}, [a, b]):
          macro STuple([${drive(a, pos, gen)}, ${drive(b, pos, gen)}]);
        case TAbstract(_.get() => {pack: ['haxe', 'ds'], name: 'Vector'}, [t]):
          this.array(drive(t, pos, gen));
        case TAbstract(_.get() => {pack: [], name: 'UInt'}, _)
           | TAbstract(_.get() => {pack: ['haxe'], name: 'UInt32'}, _):
          macro SPrimitive(PInt(null, 0));
        case TEnum(_.get().module => 'haxe.ds.Either', [left, right]):
          macro SOneOf([${drive(left, pos, gen)}, ${drive(right, pos, gen)}]);
        case TAbstract(_.get().module => 'tink.json.Serialized', [t]):
          // Serialized<T> is output verbatim, i.e. the wire format is that of T
          drive(t, pos, gen);
        case TAbstract(_.get().module => 'tink.core.Lazy', [t]):
          drive(t, pos, gen);
        default: super.drive(type, pos, gen);
      }
  }
}
#end

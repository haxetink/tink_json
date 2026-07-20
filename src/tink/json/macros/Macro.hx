package tink.json.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.ds.Option;
import tink.macro.BuildCache;

import tink.typecrawler.*;
import tink.typecrawler.Generator.EnumConstructor;

using haxe.macro.Tools;
using StringTools;
using tink.MacroApi;
using tink.CoreApi;

enum JsonTagField {
  Const(name:String, value:Expr);
  Present(name:String, pos:Position);
}

class Macro {

  static function compact(?prefix:String = '', ?fields:Array<Field>) {
    #if tink_json_compact_code
    if (fields == null)
      fields = Context.getBuildFields();
    for (i in 0...fields.length) {
      var f = fields[i];

      if(f.name == 'new') continue;

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

  static public function buildParser(?type, ?pos):Type
    return BuildCache.getType('tink.json.Parser', type, pos, parser, normalize);

  static public function nameNiladic(c:EnumField)
    return
      switch c.meta.extract(':json') {
        case []: c.name;
        case [{ params:[{ expr: EConst(CString(v)) }]}]: v;
        case v: c.pos.error('invalid use of @:json');
      }

  static public function isUnderscore(e:Expr):Bool
    return switch e {
      case { expr: EConst(CIdent('_')) }: true;
      case _: false;
    }

  static public function parseJsonTagFields(obj:Array<ObjectField>):Array<JsonTagField> {
    final out = [];
    for (f in obj) {
      if (isUnderscore(f.expr))
        out.push(Present(f.field, f.expr.pos));
      else
        out.push(Const(f.field, f.expr));
    }
    return out;
  }

  static public function extractObjectJsonTag(meta:MetaAccess):Null<Array<JsonTagField>>
    return switch meta.extract(':json') {
      case []: null;
      case [{ params: [{ expr: EObjectDecl(obj) }] }]: parseJsonTagFields(obj);
      case [{ params: [{ expr: EConst(CString(_)) }] }]: null;
      case [m]: m.pos.error('invalid use of @:json');
      case v: v[1].pos.error('duplicate @:json metadata not allowed');
    }

  static public function enumLevelTag(ct:ComplexType, pos:Position):Array<JsonTagField> {
    final t = switch ct.toType() {
      case Success(t): t;
      case Failure(e): return pos.error(e.message);
    }
    return switch t.reduce() {
      case TEnum(_.get() => e, _):
        switch e.meta.extract(':json') {
          case []: [];
          case [{ params: [{ expr: EObjectDecl(obj) }] }]: parseJsonTagFields(obj);
          case [m]: m.pos.error('@:json on enum type must be an object literal');
          case v: v[1].pos.error('duplicate @:json metadata not allowed on enum type');
        }
      case _: [];
    }
  }

  static public function isObjectTaggedCtor(c:EnumField):Bool
    return switch c.meta.extract(':json') {
      case [{ params: [{ expr: EObjectDecl(_) }] }]: true;
      case _: false;
    }

  static public function mergeTags(enumLevel:Array<JsonTagField>, ctorLevel:Array<JsonTagField>, pos:Position):Array<JsonTagField> {
    final byName = new Map<String, Bool>();
    final out = [];
    function add(t:JsonTagField) {
      final name = switch t {
        case Const(n, _): n;
        case Present(n, _): n;
      }
      if (byName.exists(name))
        pos.error('Duplicate @:json tag field "$name" across enum-level and constructor-level metadata');
      byName[name] = true;
      out.push(t);
    }
    for (t in enumLevel) add(t);
    for (t in ctorLevel) add(t);
    return out;
  }

  static public function validatePresentTags(tags:Array<JsonTagField>, fields:Array<FieldInfo>, pos:Position) {
    final names = [for (f in fields) f.name => true];
    for (t in tags) switch t {
      case Present(name, p) if (!names.exists(name)):
        p.error('@:json({ $name: _ }) requires a constructor field named "$name"');
      case Const(name, value) if (names.exists(name)):
        value.pos.error('@:json const tag "$name" collides with a constructor field of the same name');
      case _:
    }
  }

  static public function requireObjectTaggedCtors(enumLevel:Array<JsonTagField>, constructors:Array<EnumConstructor>, pos:Position) {
    if (enumLevel.length == 0) return;
    for (c in constructors)
      if (!isObjectTaggedCtor(c.ctor))
        c.ctor.pos.error('Enum-level @:json requires every constructor to use @:json({...}) object tags');
  }

  static public function printConstTags(tags:Array<JsonTagField>):String {
    final parts = [];
    for (t in tags) switch t {
      case Const(name, value):
        parts.push(haxe.format.JsonPrinter.print(name) + ':' + haxe.format.JsonPrinter.print(getExprValue(value)));
      case Present(_):
    }
    return '{' + parts.join(',') + '}';
  }

  static public function objectTagPrefix(tags:Array<JsonTagField>):{ prefix:String, first:Bool } {
    final printed = printConstTags(tags);
    if (printed == '{}')
      return { prefix: '{', first: true };
    return { prefix: printed.substr(0, printed.length - 1), first: false };
  }

  static public function constTagValues(tags:Array<JsonTagField>):Dynamic {
    final obj = {};
    for (t in tags) switch t {
      case Const(name, value):
        Reflect.setField(obj, name, getExprValue(value));
      case Present(_):
    }
    return obj;
  }

  static public function getExprValue(e:Expr):Dynamic
    return
      try e.getValue()
      catch (err:Dynamic)
        switch Context.typeExpr(e) {
          case { expr: TCast(te, _) }:
            Context.getTypedExpr(te).getValue();
          case te:
            e.pos.error('${te.toString()} does not have a statically known value');
        }

  static public function presenceType(t:Type):Type {
    final ct = t.toComplex({ direct: true });
    return (macro : haxe.ds.Option<$ct>).toType().sure();
  }

  static public function presentNames(tags:Array<JsonTagField>):Map<String, Bool> {
    final m = new Map();
    for (t in tags) switch t {
      case Present(name, _): m[name] = true;
      case _:
    }
    return m;
  }


  static function parser(ctx:BuildContext):TypeDefinition {
    var name = ctx.name,
        ct = ctx.type.toComplex();

    var cl = macro class $name extends tink.json.Parser.BasicParser {
      public function new() super();
    }

    function add(t:TypeDefinition)
      cl.fields = cl.fields.concat(t.fields);

    var ret = Crawler.crawl(ctx.type, ctx.pos, GenReader.new);

    cl.fields = cl.fields.concat(ret.fields);

    var catcher = macro tink.core.Error.catchExceptions;

    if (Context.defined('cs')) // https://github.com/HaxeFoundation/haxe/issues/9351
      catcher = macro ($catcher:(Void->$ct)->?Dynamic->?Dynamic->tink.core.Outcome<$ct, tink.core.Error>);

    add(macro class {
      public function parse(source):$ct @:pos(ret.expr.pos) {
        inline function clear()
          if (afterParsing.length > 0)
            afterParsing = [];// TODO: use resize and what not
        clear();
        this.init(source);
        var ret = ${ret.expr};
        for (f in afterParsing)
          f();
        clear();
        return ret;
      }
      public function tryParse(source)
        return $catcher(function ():$ct {
          var ret = parse(source);
          skipIgnored();
          if (pos < max)
            die('Invalid data after JSON document');
          return ret;
        });

    });

    compact('p', cl.fields);
    return cl;
  }

  static function normalize(t:Type):Type
    return switch t {
      case TAbstract(_.get() => { name: 'Null', pack: [] }, [t])
        #if !haxe4 | TType(_.get() => { name: 'Null', pack: []}, [t]) #end
        :
        var ct = normalize(t).toComplex({ direct: true });
        (macro : Null<$ct>).toType().sure();

      case TLazy(f): normalize(f());
      case TType(_.get() => { module: 'tink.json.Cached' }, [t]):

        var ct = normalize(t).toComplex({ direct: true });
        (macro : tink.json.Cached<$ct>).toType().sure();

      case TType(_, _): normalize(Context.follow(t, true));
      default: t;
    }

  static public function buildWriter(?type, ?pos):Type
    return BuildCache.getType('tink.json.Writer', type, pos, writer, normalize);

  static function writer(ctx:BuildContext):TypeDefinition {
    var name = ctx.name,
        ct = ctx.type.toComplex();

    var cl = macro class $name extends tink.json.Writer.BasicWriter {
      public function new() super();
    }

    var ret = Crawler.crawl(ctx.type, ctx.pos, GenWriter.new);

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
    // trace(ComplexType.TAnonymous(cl.fields).toString());
    return cl;
  }

  static public function getRepresentation(t:Type, pos:Position) {

    switch t.reduce() {
      case TDynamic(null) | TMono(_) | TAbstract(_.get() => {name: 'Any', pack: []}, _): return None;
      default:
    }

    var ct = t.toComplex({ direct: true });

    return
      if (Context.unify(t, Context.getType('tink.json.Representation'))) {

        var rep = (macro tink.json.Representation.of((null : $ct)).get()).typeof().sure();
        var rt = rep.toComplex();

        if (!(macro ((null : tink.json.Representation<$rt>) : $ct)).typeof().isSuccess())
          pos.error('Cannot represent ${t.toString()} in JSON because ${(macro : tink.json.Representation<$rt>).toString()} cannot be converted to ${t.toString()}');

        Some(rep);
      }
      else None;
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
#end
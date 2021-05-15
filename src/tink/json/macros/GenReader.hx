package tink.json.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.ds.Option;
import tink.typecrawler.Crawler;
import tink.typecrawler.FieldInfo;
import tink.typecrawler.Generator;

using haxe.macro.Tools;
using tink.MacroApi;
using tink.CoreApi;
using StringTools;

class GenReader extends GenBase {
  public function new(crawler) {
    super(':jsonParse', crawler);
  }

  static var OPTIONAL:Metadata = [{ name: ':optional', params:[], pos: (macro null).pos }];

  public function wrap(placeholder:Expr, ct:ComplexType):Function
    return placeholder.func(ct);

  public function nullable(e)
    return macro
      if (this.allow('null')) null;
      else $e;

  public function string()
    return macro (this.parseString().toString() : String);

  public function int()
    return macro this.parseNumber().toInt();

  public function float()
    return macro this.parseNumber().toFloat();

  public function bool()
    return macro this.parseBool();

  public function date()
    return macro Date.fromTime(this.parseNumber().toFloat());

  public function bytes()
    return macro haxe.crypto.Base64.decode(this.parseString().toString());

  public function map(k, v)
    return macro {
      this.expect('[');
      var __ret = new #if haxe4 haxe.ds.Map #else Map #end();
      if (!allow(']')) {
        do ${tuple([k, v], values -> macro __ret.set(${values[0]}, ${values[1]}))}
        while (allow(','));
        expect(']');
      }
      __ret;
    }

  function tuple(elements:Array<Expr>, make, ?out) {
    var exprs = [macro this.expect('[')];

    var vars = [];
    for(i in 0...elements.length) {
      var name = '_e$i';
      var e = elements[i];
      exprs.push(macro var $name = ${i == 0 ? e : macro this.expect(',') & $e});
      vars.push(macro $i{name});
    }

    exprs.push(make(vars));
    exprs.push(macro this.expect(']'));
    if(out != null) exprs.push(out);

    return macro $b{exprs};
  }

  static final IGNORE_MISSING_FIELDS = Context.defined('tink_json.ignore_missing_fields');

  public function anon(fields:Array<FieldInfo>, ct) {

    var vars:Array<Var> = [{ name: 'cur', expr: macro 0, type: null }],
        obj = [],
        byName = new Map();

    EObjectDecl(obj);//help type inference

    for (f in fields) {
      var ct = f.type.toComplex(),
          name = 'v_' + f.name,
          jsonName = Macro.nativeName(f),
          optional = f.optional || IGNORE_MISSING_FIELDS;

      var option = switch f.type.reduce() {
        case TEnum(_.get() => {pack:['haxe','ds'], name:'Option'}, [v]): Some(v);
        default: None;
      }

      var defaultValue = switch f.meta.getValues(':default') {
        case []: None;
        case [[v]]:
          if (option == None)
            Some(v)
          else v.reject('Cannot specify default for `Option`');
        case v: f.pos.error('more than one @:default');
      }

      var hasName = 'has$name';

      byName[jsonName] = macro {
        ${
          switch option {
            case Some(t):
              macro $i{name} = Some(${f.as(t)});
            default:
              macro $i{name} = ${f.expr};
          }
        }
        ${
          if (optional) macro $b{[]}
          else macro $i{hasName} = true
        }
      };

      obj.push({
        field: f.name,
        expr:
          switch option {
            case Some(v):
              if (optional)
                macro switch $i{name} {
                  case null: None;
                  case v: v;
                }
              else macro if ($i{hasName}) $i{name} else None;
            case None:
              if (optional || defaultValue != None) macro $i{name}
              else macro if ($i{hasName}) $i{name} else __missing__($v{jsonName});
          },
      });

      if (optional)
        vars.push(switch defaultValue {
          case None: {
            name: name,
            expr: macro null,
            type: macro : Null<$ct>
          }
          case Some(v): {
            name: name,
            expr: v,
            type: ct
          }
        });
      else {

        var valType =
          switch Crawler.plainAbstract(f.type) {
            case Some(a): a;
            default: f.type;
          }

        vars.push({
          name: name,
          expr: switch defaultValue {
            case Some(v): v;
            default: switch Context.followWithAbstracts(valType).getID() {
              case 'Bool': macro cast false;
              case 'Int' | 'UInt': macro cast 0;
              case 'Float': macro cast .0;
              default: macro null;
            } // for working around the uninitialized var check, note that this initial value is unimportant because it is guaranteed to be rewritten
          },
          type: ct,
        });

        vars.push({
          type: macro : Bool,
          name: hasName,
          expr: macro false,
        });
      }

    };

    var branch = {
      function toExpr(b:Branch):Expr {
        var cases = new Array<Case>();
        switch b.expr {
          case null:
          case v:
            cases.push({
              values: [macro '"'.code],
              expr: macro { this.toChar(':'.code, ':'); skipIgnored(); $v; continue; } });
        }

        for (code => b in b.children)
          cases.push({ values: [macro $v{code}], expr: toExpr(b) });

        return ESwitch(macro cur = this.next(), cases, null).at((macro null).pos);
      }

      function make():Branch
        return { children: new Map() };
      var root = make();
      for (name => expr in byName) {
        var cur = root;
        for (c in name)
          cur = switch cur.children[c] {
            case null: cur.children[c] = make();
            case v: v;
          }
        cur.expr = expr;
      }
      toExpr(root);
    }

    return macro {

      ${EVars(vars).at()};

      var __start__ = this.pos;
      this.toChar('{'.code, '{');
      if (!this.allow('}')) {
        do {
          this.toChar('"'.code, '"');
          $branch;
          if (cur != '"'.code) skipString();
          this.toChar(':'.code, ':');
          this.skipIgnored();
          this.skipValue();
        } while (this.allow(',', true, false));
        this.expect('}');
      }

      function __missing__(field:String):Dynamic {
        return this.die('missing field "' + field + '"', __start__);
      };

      (${EObjectDecl(obj).at()} : $ct);
    };
  }

  public function array(e)
    return macro {
      this.expect('[');
      var __ret = [];
      if (!allow(']')) {
        do {
          __ret.push($e);
        } while (allow(','));
        expect(']');
      }
      __ret;
    }

  public function enm(constructors:Array<EnumConstructor>, ct:ComplexType, pos:Position, gen:GenType) {
    if(constructors.length == 0) pos.error('Enum ${ct.toString()} has no constructors and tink_json can\'t handle it');
    var fields = new Map<String, LiteInfo>(),
        cases = new Array<Case>();

    function captured(f:String)
      return macro @:pos(pos) $i{
        if (f.charAt(0).toUpperCase() == f.charAt(0)) '__'+f.toLowerCase()
        else f
      };

    function add(f:LiteInfo)
      switch fields[f.name] {
        case null: fields[f.name] = f;
        case same if (Crawler.typesEqual(same.type, f.type)):
          fields[f.name] = {
            pos: f.pos,
            name: f.name,
            access: f.access,
            type: f.type,
            optional: same.optional || f.optional,
          }
        case other:
          fields[f.name] = {
            pos: f.pos,
            name: f.name,
            access: f.access,
            type: (macro:tink.json.Serialized<tink.core.Any>).toType().sure(),
            optional: other.optional || f.optional,
          }
      }

    function mkComplex(fields:Iterable<LiteInfo>):ComplexType
      return TAnonymous([for (f in fields) {
        name: f.name,
        pos: f.pos,
        meta: if (f.optional) OPTIONAL else [],
        kind: FProp(f.access.get, f.access.set, f.type.toComplex()),
      }]);

    var argLess = [];
    for (c in constructors) {

      var nullable = isInlineNullable(c),
          inlined = c.inlined,
          cfields = c.fields,
          c = c.ctor,
          name = c.name,
          hasArgs = !c.type.reduce().match(TEnum(_,_));

      switch c.meta.extract(':json') {
        case [] if(!hasArgs):
            argLess.push(new Named(name, name));
        case []:

          add({
            name: name,
            optional: true,
            type: mkComplex(cfields).toType().sure(),
            pos: c.pos,
            access: { get: 'default', set: 'default' },
          });

          cases.push({
            values: [macro { $name : o }],
            guard: if (nullable) macro true else macro o != null,
            expr: {
              var args =
                if (inlined) [macro o];
                else [for (f in cfields) {
                  var name = f.name;
                  macro o.$name;
                }];

              switch args {
                case []: macro ($i{name} : $ct);
                case _: macro ($i{name}($a{args}) : $ct);
              }
            }
          });

        case [{ params:[{ expr: EConst(CString(v)) }]}] if(!hasArgs):
          argLess.push(new Named(name, v));

        case [{ params:[{ expr: EObjectDecl(obj) }] }]:
          if(hasArgs) {
            for (f in cfields) {
              add(f.makeOptional());
            }
          }

          for (f in obj)
            add({
              pos: f.expr.pos,
              name: f.field,
              type: f.expr.typeof().sure(),
              optional: true,
              access: { get: 'default', set: 'default' },
            });

        case v:
          c.pos.error('invalid use of @:json');
      }
    }

    // second pass for @:json
    for (c in constructors) {
      switch c.ctor.meta.extract(':json') {
        case [{ params:[{ expr: EObjectDecl(obj) }] }]:

          var pat = obj.copy(),
              guard = macro true;

          for(f in c.fields) {
            if (!(f.optional || isNullable(f.type)))
              guard = macro $guard && ${captured(f.name)} != null;

            pat.push({ field: f.name, expr: macro ${captured(f.name)}});
          }

          function read(f:FieldInfo) {
            var e = captured(f.name);
            return if(fields[f.name].type.getID() == 'tink.json.Serialized') {
              var ct = f.type.toComplex();
              if(f.optional) {
                macro {
                  var s = $e;
                  s == null ? null : (cast s:tink.json.Serialized<$ct>).parse();
                }
              } else {
                macro (cast $e:tink.json.Serialized<$ct>).parse();
              }
            } else {
              e;
            }
          }

          var args =
            if (c.inlined) [EObjectDecl([for (f in c.fields) { field: f.name, expr: read(f) }]).at(pos)];
            else [for (f in c.fields) read(f)];

          var call = switch args {
            case []: macro ($i{c.ctor.name} : $ct);
            case _: macro ($i{c.ctor.name}($a{args}) : $ct);
          }

          cases.push({
            values: [EObjectDecl(pat).at()],
            guard: guard,
            expr: call
          });
        case _:
      }
    }

    var ret = macro {
      var __ret = ${gen(mkComplex(fields).toType().sure(), pos)};
      ${ESwitch(
        macro __ret,
        cases,
        macro throw new tink.core.Error(422, 'Cannot process '+Std.string(__ret))
      ).at(pos)};
    }

    return
      if (argLess.length == 0) ret;
      else {

        var argLessSwitch = ESwitch(macro parseRestOfString().toString(), [for (a in argLess) {
          values: [macro $v{a.value}], expr: macro $i{a.name},
        }].concat([{
          values: [macro invalid], expr: macro throw new tink.core.Error(422, 'Invalid constructor '+invalid),
        }]), null).at(pos);

        macro if (allow('"')) $argLessSwitch else $ret;
      }
  }

  public function enumAbstract(names:Array<Expr>, e:Expr, ct:ComplexType, pos:Position):Expr {
    // get the values of the enum abstract statically
    final values = names.map(e -> {
      final e = macro ($i{e.toString().split('.').pop()}:$ct); // this ECheckType + DirectType approach makes sure we can punch through the type system even if the abstract is private
      switch Context.typeExpr(e) {
        case {expr: TParenthesis({expr: TCast({expr: TCast(texpr, _)}, _)})}:
          Context.getTypedExpr(texpr);
        case _:
          throw 'TODO';
      }
    });

    return macro @:pos(pos) {
      final v = $e;
      ${ESwitch(
        macro v,
        [{expr: macro (cast v:$ct), values: values}],
        macro throw new tink.core.Error(422, 'Unrecognized enum value: ' + v + '. Accepted values are: ' + tink.Json.stringify(${macro $a{values}}))
      ).at(pos)}
    }
  }

  public function dyn(e, ct)
    return macro ($e : Dynamic<$ct>);

  public function dynAccess(e)
    return macro {
      this.expect('{');
      var __ret = new haxe.DynamicAccess();
      if (!allow('}')) {
        do {
          __ret[this.parseString().toString()] = expect(':') & $e;
        } while (allow(','));
        expect('}');
      }
      __ret;
    }

  override function processDynamic(pos)
    return macro @:pos(pos) this.parseDynamic();

  override function processValue(pos)
    return macro @:pos(pos) this.parseValue();

  override function processSerialized(pos)
    return macro @:pos(pos) this.parseSerialized();

  override function processLazy(t, pos)
    return macro @:pos(pos) {
      var v:tink.json.Serialized<$t> = this.parseSerialized();
      tink.core.Lazy.ofFunc(function () return v.parse());
    }

  static var aliasCount = 0;
  override function processCustom(c:CustomRule, original:Type, gen:Type->Expr) {
    var original = original.toComplex();

    return switch c {
      case WithClass(path, pos):
        var rep = (macro @:pos(pos) { var f = null; (new $path(null).parse(f()) : $original); f(); }).typeof().sure();

        var dotpath = switch path.params {
          case []:
            var tmp = path.pack.concat([path.name]);
            if(path.sub != null) tmp.push(path.sub);
            macro $p{tmp}
          case _: // the type has type parameters
            // because we don't have expr to represent a complex type...
            // so we typedef the type then use its typepath
            var tmp = ['tink', 'json', 'tmpread', 'Temp${aliasCount++}'];
            haxe.macro.Context.defineType({
              pos: pos,
              pack: tmp.slice(0, tmp.length - 1),
              name: tmp[tmp.length - 1],
              kind: TDAlias(TPath(path)),
              fields: [],
            });
            macro $p{tmp}
        }
        macro @:pos(pos) this.plugins.get($dotpath).parse(${gen(rep)});
      case WithFunction(e):

        var rep = (macro @:pos(e.pos) { var f = null; ($e(f()) : $original); f(); }).typeof().sure();

        macro @:pos(e.pos) $e(${gen(rep)});
    }
  }

  override function processRepresentation(pos:Position, actual:Type, representation:Type, value:Expr):Expr {
    var rt = actual.toComplex();
    var ct = representation.toComplex();

    return macro @:pos(pos) {
      var __start__ = this.pos,
          rep = $value;

      try {
        (new tink.json.Representation<$ct>(rep) : $rt);
      }
      catch (e:Dynamic) {
        this.die(Std.string(e), __start__);
      }
    };
  }

  override function genCached(id:Int, normal:Expr, type:Type) {
    var map = 'cache$id',
        counter = 'counter$id';

    crawler.add(macro class {
      var $map = new Map();
      var $counter = 0;
    });

    function withPlaceholder(e) {
      var ct = type.toComplex();
      return macro {
        var ret:$ct = $e;
        $i{map}[$i{counter}++] = ret;
        copyFields(ret, $normal);
      }
    }

    function plain()
      return macro $i{map}[$i{counter}++] = $normal;

    var read = switch type.reduce() {//TODO: check if its circular at all
      case TInst(_.get() => cl, _):
        switch cl {
          case { pack: [], name: 'String' }: plain();
          case { isPrivate: true }:
            cl.pos.warning('cached private classes may not always work as expected');
            plain();
          default:
            withPlaceholder(macro emptyInstance($p{cl.module.split('.').concat([cl.name])}));
          }
      case TAnonymous(_):
        withPlaceholder(macro cast {});
      case t:
        normal.pos.error('No support for Cached<${t.toString()}> yet');
    }

    return
      macro
        if (tink.json.Parser.BasicParser.startsNumber(source.getChar(pos))) {
          var start = pos;
          var id = this.parseNumber().toInt();
          if (id >= $i{counter}) die('attempting to reference unknown object', start, pos);
          else $i{map}[id];
        }
        else $read;
  }


  public function reject(t:Type)
    return 'tink_json cannot parse ${t.toString()}. For parsing custom data, please see https://github.com/haxetink/tink_json#custom-parsers';

  override public function drive(type:Type, pos:Position, gen:GenType):Expr
    return
      switch type.reduce() {
        case TAbstract(_.get() => {pack: ['tink', 'core'], name: 'Pair'}, [a, b]):
          this.tuple([gen(a, pos), gen(b, pos)], values -> (macro var __ret = new tink.core.Pair(${values[0]}, ${values[1]})), macro __ret);
        case TAbstract(_.get() => {pack: ['haxe', 'ds'], name: 'Vector'}, [t]):
          macro haxe.ds.Vector.fromArrayCopy(${this.array(gen(t, pos))});
        case TAbstract(_.get() => {pack: [], name: 'UInt'}, _):
          macro this.parseNumber().toUInt();
        default: super.drive(type, pos, gen);
      }
}

private typedef LiteInfo = {
  var name(default, never):String;
  var pos(default, never):Position;
  var type(default, never):Type;
  var optional(default, never):Bool;
  var access(default, never):FieldAccessInfo;
}

private typedef Branch = { ?expr:Expr, children:Map<Int, Branch> };
#end

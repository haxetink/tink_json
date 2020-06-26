package tink.json.macros;

#if macro
import haxe.ds.Option;
import haxe.macro.Type;
import haxe.macro.Expr;
import tink.typecrawler.FieldInfo;
import tink.typecrawler.Generator;

using haxe.macro.Tools;
using tink.MacroApi;

class GenWriter extends GenBase {
  static public var inst(default, null) = new GenWriter();

  function new() {
    super(':jsonStringify');
  }

  public function wrap(placeholder:Expr, ct:ComplexType):Function
    return placeholder.func(['value'.toArg(ct)], false);

  public function nullable(e)
    return macro if (value == null) this.output('null') else $e;

  public function string()
    return macro this.writeString(value);

  public function int()
    return macro this.writeInt(value);

  public function float()
    return macro this.writeFloat(value);

  public function bool()
    return macro this.writeBool(value);

  public function date()
    return macro this.writeFloat(value.getTime());

  public function bytes()
    return macro this.writeString(haxe.crypto.Base64.encode(value));

  public function map(k, v)
    return macro {
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
          $k;
        }

        this.char(','.code);
        {
          var value = value.get(k);
          $v;
        }

        this.char(']'.code);
      }
      this.char(']'.code);
    }

  public function anon(fields:Array<FieldInfo>, ct)
    return if(fields.length == 0)
      macro this.output('{}');
    else {
      fields = fields.copy();
      fields.sort(function (a, b)
        return switch [a.optional, b.optional] {
          case [false, true]: -1;
          case [true, false]: 1;
          case [x, y]: Reflect.compare(a.name, b.name);
        }
      );

      var hasMandatory = !fields[0].optional;
      if (!hasMandatory) macro {
        var __first = true;

        this.char('{'.code);
        $b{[for (f in fields) {
          var name = f.name,
              field = '"${Macro.nativeName(f)}":';

          function write(value, expr)
            return macro {
              if (__first)
                __first = false;
              else
                this.char(','.code);
              this.output($v{field});
              var value = $value;
              $expr;
            }

          switch f.type.reduce() {
            case TEnum(_.get() => {name: 'Option', pack: ['haxe', 'ds']}, [t]):
              macro switch @:privateAccess value.$name {
                case null | None:
                case Some(v): ${write(macro v, f.as(t))};
              }
            default:
              macro switch @:privateAccess value.$name {
                case null:
                case v: ${write(macro @:privateAccess value.$name, f.expr)};
              }
            }
        }]};
        this.char('}'.code);
      }
      else macro {
        var __first = true;
        this.char('{'.code);

        $b{[for (f in fields) {
          var name = f.name,
              field = '"${Macro.nativeName(f)}":';

          var write = macro {
            if(__first) __first = false;
            else this.char(','.code);
            this.output($v{field});
            ${f.expr};
          }

          switch f.type.reduce() {
            case TEnum(_.get() => {name: 'Option', pack: ['haxe', 'ds']}, [t]):
              macro switch @:privateAccess value.$name {
                case null | None:
                case Some(value):
                  if(__first) __first = false;
                  else this.char(','.code);
                  this.output($v{field});
                  ${f.as(t)};
              }
            default:
              if (f.optional)
                macro switch @:privateAccess value.$name {
                  case null:
                  case value: $write;
                }
              else
                macro {
                  var value = @:privateAccess value.$name;
                  $write;
                }
          }
        }]};
        this.char('}'.code);
      };
    }

  public function array(e)
    return macro {
      this.char('['.code);
      var first = true;
      for (value in value) {
        if (first)
          first = false;
        else
          this.char(','.code);
        $e;
      }
      this.char(']'.code);
    };

  public function enm(constructors:Array<EnumConstructor>, ct:ComplexType, pos:Position, _) {
    if(constructors.length == 0) pos.error('Enum ${ct.toString()} has no constructors and tink_json can\'t handle it');
    var cases = [];
    for (c in constructors) {
      var nullable = isInlineNullable(c),
          cfields = c.fields,
          inlined = c.inlined,
          c = c.ctor,
          name = c.name,
          postfix = '}',
          first = true;
      cases.push(
        if (c.type.reduce().match(TEnum(_,_)))
          {
            values: [macro $i{name}],
            expr: (macro this.output($v{haxe.format.JsonPrinter.print(
              switch c.meta.extract(':json') {
                case []: c.name;
                case [{ params:[{ expr: EConst(CString(v)) }]}]: v;
                case [{ params:[{ expr: EObjectDecl(obj) }] }]: ExprTools.getValue(EObjectDecl(obj).at());
                case _: c.pos.error('invalid use of @:json');
              }
            )})),
          }
        else {
          var prefix =
            switch c.meta.extract(':json') {
              case []:

                postfix = '}}';
                '{"$name":' + if (nullable) '' else '{';

              case _ if (nullable):

                c.pos.error('@:json cannot be nullable');

              case [{ params:[{ expr: EObjectDecl(obj) }] }]:

                first = false;
                var ret = haxe.format.JsonPrinter.print(ExprTools.getValue(EObjectDecl(obj).at()));
                ret.substr(0, ret.length - 1);

              default:
                c.pos.error('invalid use of @:json');
            }

          var args =
            if (inlined) [macro value]
            else [for (f in cfields) macro $i{f.name}];

          {
            values: [macro @:pos(c.pos) ${args.length == 0 ? macro $i{name} : macro $i{name}($a{args})}],
            expr: macro {
              this.output($v{prefix});
              if (${if (nullable) macro value == null else macro false}) this.output('null}');
              else {
                $b{[for (f in cfields) {
                  var fname = f.name;
                  macro {
                    this.output($v{'${if (first) { first = false; ""; } else ","}"${f.name}"'});
                    this.char(':'.code);
                    {
                      var value = ${
                        if (inlined)
                          macro value.$fname
                        else
                          macro $i{f.name}
                      }
                      ${f.expr};
                    }
                  }
                }]}
                this.output($v{postfix});
              }
            },
          };
        }
      );
    }
    return ESwitch(macro (value:$ct), cases, null).at();
  }

  public function enumAbstract(names:Array<Expr>, e:Expr, ct:ComplexType, pos:Position):Expr {
    return macro @:pos(pos) {
      var value = cast value;
      $e;
    }
  }

  public function dyn(e, ct)
    return macro {
      var value:haxe.DynamicAccess<$ct> = value;
      $e;
    }

  public function dynAccess(e)
    return macro {
      var first = true;

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
          $e;
        }

      }
      this.char('}'.code);
    }

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
        //TODO: the two cases look suspiciously similar
        var rep = (macro @:pos(e.pos) { var f = null; $e((f():$original)); }).typeof().sure();
        return macro @:pos(e.pos) {
          var value = $e(value);
          ${gen(rep)};
        }
    }
  }

  override public function drive(type:Type, pos:Position, gen:Type->Position->Expr):Expr
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
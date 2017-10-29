package tink.json.macros;

import haxe.ds.Option;
import haxe.macro.Type;
import haxe.macro.Expr;
import tink.typecrawler.FieldInfo;
import tink.typecrawler.Generator;

using haxe.macro.Tools;
using tink.MacroApi;

class GenWriter {
  static public function wrap(placeholder:Expr, ct:ComplexType):Function
    return placeholder.func(['value'.toArg(ct)], false);
    
  static public function nullable(e) 
    return macro if (value == null) this.output('null') else $e;
    
  static public function string() 
    return macro this.writeString(value);
    
  static public function int() 
    return macro this.writeInt(value);
    
  static public function float() 
    return macro this.writeFloat(value);
    
  static public function bool() 
    return macro this.writeBool(value);
    
  static public function date() 
    return macro this.writeFloat(value.getTime());
    
  static public function bytes() 
    return macro this.writeString(haxe.crypto.Base64.encode(value));
    
  static public function map(k, v)               
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
    
  static public function anon(fields:Array<FieldInfo>, ct) 
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
            
          var write = macro {
            if (__first)
              __first = false;
            else
              this.char(','.code);
            this.output($v{field});
            var value = @:privateAccess value.$name;
            ${f.expr};    
          }
          
          if(f.type.getID() == 'haxe.ds.Option')
            macro switch @:privateAccess value.$name {
              case null | None:
              case Some(v): $write;
            }
          else
            macro switch @:privateAccess value.$name {
              case null:
              case v: $write;
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
        
          if(f.type.getID() == 'haxe.ds.Option')
            macro switch @:privateAccess value.$name {
              case null | None:
              case Some(value):
                if(__first) __first = false;
                else this.char(','.code);
                this.output($v{field});
                this.output(tink.Json.stringify(value));
            }
          else if (f.optional)
            macro switch @:privateAccess value.$name {
              case null:
              case value: $write;
            }
          else 
            macro {
              var value = @:privateAccess value.$name;
              $write;
            }
        }]};
        this.char('}'.code);
      };
    }

  static public function array(e) 
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
    
  static public function enm(constructors:Array<EnumConstructor>, ct, _, _) {
    var cases = [];
    for (c in constructors) {
      var cfields = c.fields,
          inlined = c.inlined,
          c = c.ctor,
          name = c.name,
          postfix = '}',
          first = true;      
      cases.push(
        if (c.type.reduce().match(TEnum(_,_))) 
          {
            values: [macro $i{name}],
            expr: (macro this.output($v{haxe.format.JsonPrinter.print(Macro.nameNiladic(c))})),
          }
        else {
          var prefix = 
            switch c.meta.extract(':json') {
              case []:
                
                postfix = '}}';
                '{"$name":{';
                
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
            },
          };            
        }    
      );
    }
    return ESwitch(macro (value:$ct), cases, null).at();
  }
  
  static public function enumAbstract(names:Array<Expr>, e:Expr, ct:ComplexType, pos:Position):Expr {
    return macro @:pos(pos) {
      var value = cast value;
      $e;
    }
  }
  
  static public function dyn(e, ct) 
    return macro {
      var value:haxe.DynamicAccess<$ct> = value;
      $e;
    }
    
  static public function dynAccess(e)
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
    
  static public function rescue(t:Type, pos:Position, gen:GenType):Option<Expr>
    return 
      switch t.reduce() {
        
        case TInst(_.get() => { isInterface: true }, _):
          
          pos.error('Interfaces cannot be stringified. ');
        
        case TInst(_.get() => cl, params):
          //TODO: this should be handled by converting the class to an anonymous type and handing that off to `gen`
          var a = new Array<FieldInfo>();
          
          for (f in cl.fields.get()) 
            if (Macro.shouldSerialize(f)) {
              var ft = f.type.applyTypeParameters(cl.params, params);
              a.push(new FieldInfo({ name: f.name, pos: f.pos, type: ft }, gen, false, f.meta.get()));
            }
          
          Some(anon(a, t.toComplex()));
          
        default:
          
          switch Macro.getRepresentation(t, pos) {
            case Some(v):
              
              var ct = v.toComplex();
              
              Some(macro @:pos(pos) {
                var value = (value : tink.json.Representation<$ct>).get();
                ${gen(v, pos)};
              });
              
            default:
              
              None;
          }                  
      }    
      
  static public function reject(t:Type) 
    return 'Cannot stringify ${t.toString()}';
    
  static public function shouldIncludeField(c:ClassField, owner:Option<ClassType>):Bool
    return Helper.shouldIncludeField(c, owner);
    
  static public function drive(type:Type, pos:Position, gen:Type->Position->Expr):Expr
    return
      switch type.reduce() {
        case TDynamic(null): macro @:pos(pos) 
          this.writeDynamic(value);
        case TEnum(_.get().module => 'tink.json.Value', _): 
          macro @:pos(pos) this.writeValue(value);
        case TEnum(_.get().module => 'haxe.ds.Either', [left, right]):
          var lct = left.toComplex();
          var rct = right.toComplex();
          macro @:pos(pos) switch value {
            case Left(v): this.output(tink.Json.stringify((v:$lct)));
            case Right(v): this.output(tink.Json.stringify((v:$rct)));
          }
        case TAbstract(_.get().module => 'tink.json.Serialized', _): 
          macro @:pos(pos) this.output(value);
        case v:
          switch type.getMeta().filter(function (m) return m.has(':jsonStringify')) {
            case []: gen(type, pos);
            case v: 
              switch v[0].extract(':jsonStringify')[0] {
                case { params: [writer] }: 
                  
                  var path = writer.toString().asTypePath();

                  var rep = 
                    switch (macro @:pos(writer.pos) new $path(null).prepare).typeof().sure().reduce() {
                      case TFun([{ t: t }], ret): ret;
                      default: writer.reject('field `prepare` has wrong signature');
                    }
                    //throw rep;
                  macro @:pos(writer.pos) {
                    var value = this.plugins.get($writer).prepare(value);
                    ${drive(rep, pos, gen)};
                  }
                case v: v.pos.error('@:jsonStringify must have exactly one parameter');
              }
          }
        }

}

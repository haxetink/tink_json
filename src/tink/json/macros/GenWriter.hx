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
    else
      macro {
        $b{[for (f in fields) {
          var name = f.name;
          var field = (
            if (f == fields[0]) '{'
            else ','
          ) + '"${Macro.nativeName(f)}":';
          
          macro {
            this.output($v{field});
            var value = @:privateAccess value.$name;
            ${f.expr};
          }
        }]};
        this.char('}'.code);
      };
    
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
  
  static public function enumAbstract(names:Array<String>, e:Expr):Expr {
    throw 'not implemented';
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
          
          var a = new Array<FieldInfo>();
          
          for (f in cl.fields.get()) 
            if (Macro.shouldSerialize(f)) {
              var ft = f.type.applyTypeParameters(cl.params, params);
              a.push({
                name: f.name,
                meta: f.meta.get(),
                type: ft,
                expr: gen(ft, f.pos),
                optional: false,
                pos: f.pos
              });
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
    return gen(type, pos);
}

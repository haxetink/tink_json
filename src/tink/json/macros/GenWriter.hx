package tink.json.macros;

import haxe.macro.Type;
import haxe.macro.Expr;
import tink.typecrawler.FieldInfo;
import tink.typecrawler.Generator;

using haxe.macro.Tools;
using tink.MacroApi;

class GenWriter {
  static public function args() 
    return ['value'];
    
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
    return (macro function (value:$ct) {
      var open = '{';
      $b{[for (f in fields) {
        var name = f.name;
        macro {
          this.output('${if (f == fields[0]) "$open" else ","}"$name":');
          var value = value.$name;
          ${f.expr};
        }
      }]};
      char('}'.code);
    }).getFunction().sure();
    
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
        
        cases.push({
          values: [macro @:pos(c.pos) $i{name}($a{args})],
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
        });            
    }
    return ESwitch(macro value, cases, null).at();
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
    
  static public function rescue(t:Type, pos:Position, gen:GenType) 
    return switch Macro.getRepresentation(t, pos) {
      case Some(v):
        
        var ct = v.toComplex();
        
        Some(macro @:pos(pos) {
          var value = (value : tink.json.Representation<$ct>).get();
          ${gen(v, pos)};
        });
        
      default:
        
        None;
    }        
    
  static public function reject(t:Type) 
    return 'Cannot stringify ${t.toString()}';
}
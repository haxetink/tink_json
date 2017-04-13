package tink.json;

import haxe.Utf8;

@:genericBuild(tink.json.macros.Macro.buildWriter())
class Writer<T> {}

class BasicWriter {
  var buf:StringBuf;
  
  function init() {
    buf = new StringBuf();
  }
  
  inline function output(s:String) 
    buf.add(s);
    
  inline function char(c:Int)
    buf.addChar(c);
    
  inline function writeInt(v:Int)
    output(Std.string(v));
    
  inline function writeFloat(v:Float)
    output(Std.string(v));
    
  inline function writeBool(b:Bool)
    output(if (b) 'true' else 'false');
    
  inline function writeString(s:String) 
    output(StringWriter.stringify(s));
  
  function writeValue(value:Value)
    switch value {
      case VNumber(f): writeFloat(f);
      case VString(s): writeString(s);
      case VNull: output('null');
      case VBool(b): output(if (b) 'true' else 'false');
      case VArray([]): output('[]');
      case VArray(a): 
        
        char('['.code);
        writeValue(a[0]);
        
        for (i in 1...a.length) {
          char(','.code);
          writeValue(a[i]);
        }
        char(']'.code);
        
      case VObject([]): output('{}');
      case VObject(a):
      
        char('{'.code);
        
        inline function write(p:tink.core.Named<Value>) {
          writeString(p.name);
          char(':'.code);
          writeValue(p.value);
        }
        
        for (i in 1...a.length) {
          char(','.code);
          write(a[i]);
        }
        
        char('}'.code);      
      
    }
}

#if js
@:forward(toString)
private abstract StringBuf(String) {
  
  public inline function new() 
    this = '';
    
  public inline function addChar(c) 
    this += String.fromCharCode(c);
    
  public inline function add(s:String)
    this += s;
}

@:native("JSON")
extern private class StringWriter {
  static function stringify(s:String):String;
}
#else
private typedef StringWriter = haxe.format.Json;
#end

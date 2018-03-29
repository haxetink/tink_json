package tink.json;

using tink.CoreApi;

@:genericBuild(tink.json.macros.Macro.buildWriter())
class Writer<T> {}

#if !macro
@:build(tink.json.macros.Macro.compact())
#end
class BasicWriter {
  public var plugins(default, null):Annex<BasicWriter>;

  var buf:StringBuf;
  
  function new() 
    this.plugins = new Annex(this);

  function init() {
    buf = new StringBuf();
  }
  
  inline function output(s:String) 
    buf.add(s);
    
  inline function char(c:Char)
    buf.addChar(c);
    
  inline function writeInt(v:Int)
    output(Std.string(v));
    
  inline function writeFloat(v:Float)
    output(Std.string(v));
    
  inline function writeBool(b:Bool)
    output(if (b) 'true' else 'false');
    
  inline function writeString(s:String) 
    output(StdWriter.stringify(s));
  
  function writeDynamic(value:Dynamic) 
    output(StdWriter.stringify(value));
  
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
        write(a[0]);
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
    
  public inline function addChar(c:Char) 
    this += c.toString();
    
  public inline function add(s:String)
    this += s;
}

@:native("JSON")
extern private class StdWriter {
  static function stringify(v:Dynamic):String;
}
#else
private class StdWriter {
  static public inline function stringify(v:Dynamic):String
    return haxe.format.JsonPrinter.print(v);
}
#end

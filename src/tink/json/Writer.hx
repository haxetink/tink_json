package tink.json;
import haxe.Utf8;

@:genericBuild(tink.json.Macro.buildWriter())
class Writer<T> {
}

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
    
  function writeString(s:String) {
    char('"'.code);
    //TODO: optimize - add fast path for simple strings
    Utf8.iter(s, function (c) {
      if (c > 0x7f)
        output('\\u' + StringTools.hex(c, 4));
      else
        switch c {
          case '\n'.code: output('\\n');
          case '\r'.code: output('\\r');
          case '\t'.code: output('\\t');
          case '\''.code: output("\\'");
          case '\"'.code: output('\\"');
          case v: char(v);
        }
    });
    char('"'.code);
  }
  
}
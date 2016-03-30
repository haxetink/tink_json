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
  
  function writeNull<T>(value:Null<T>, writer:T->Void) 
    switch value {
      case null: output('null');
      case v: writer(v);
    }
    
  function writeInt(v:Int)
    output(Std.string(v));
    
  function writeFloat(v:Float)
    output(Std.string(v));
    
  function writeBool(b:Bool)
    output(if (b) 'true' else 'false');
    
  function writeString(s:String) {
    char('"'.code);
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
  
  function writeArray<T>(a:Array<T>, writer:T->Void) {
    char('['.code);
    var first = true;
    for (x in a) {
      if (first) 
        first = false;
      else
        char(','.code);
      writer(x);
    }
    char(']'.code);
  }
  
}
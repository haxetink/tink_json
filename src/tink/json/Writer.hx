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
    output(StringWriter.stringify(s));
  
  function writeDynamic(value:Dynamic) 
    output(DynamicWriter.stringify(value));
  
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
    
  function expandScientificNotation(v:String) {
    return switch v.toLowerCase().split('e') {
      case [d]: d;
      case [d, e]:
        switch d.split('.') {
          case [v]: v + StringTools.rpad('', '0', Std.parseInt(e));
          case [d, f]: d + StringTools.rpad(f, '0', Std.parseInt(e));
          case _: throw 'Invalid value';
        }
      case _: throw 'Invalid value';
    }
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
extern private class StringWriter {
  static function stringify(v:String):String;
}

@:native("JSON")
extern private class DynamicWriter {
  static function stringify(v:Dynamic):String;
}
#else
private class StringWriter {
  static public function stringify(v:String):String {
    if(v == null) return 'null';
    var buf = new StringBuf();
    quote(v, buf);
    return buf.toString();
  }
  
  static function quote( s:String, buf:StringBuf ) {
    #if (neko || php || cpp)
    if( s.length != haxe.Utf8.length(s) ) {
      quoteUtf8(s, buf);
      return;
    }
    #end
    buf.addChar('"'.code);
    var i = 0;
    while( true ) {
      var c = StringTools.fastCodeAt(s, i++);
      if( StringTools.isEof(c) ) break;
      switch( c ) {
      case '"'.code: buf.add('\\"');
      case '\\'.code: buf.add('\\\\');
      case '\n'.code: buf.add('\\n');
      case '\r'.code: buf.add('\\r');
      case '\t'.code: buf.add('\\t');
      case 8: buf.add('\\b');
      case 12: buf.add('\\f');
      default:
        #if flash
        if( c >= 128 ) buf.add(String.fromCharCode(c)) else buf.addChar(c);
        #else
        buf.addChar(c);
        #end
      }
    }
    buf.addChar('"'.code);
  }

  #if (neko || php || cpp)
  static function quoteUtf8( s:String, buf:StringBuf ) {
    var u = new haxe.Utf8();
    haxe.Utf8.iter(s,function(c) {
      switch( c ) {
      case '\\'.code, '"'.code: u.addChar('\\'.code); u.addChar(c);
      case '\n'.code: u.addChar('\\'.code); u.addChar('n'.code);
      case '\r'.code: u.addChar('\\'.code); u.addChar('r'.code);
      case '\t'.code: u.addChar('\\'.code); u.addChar('t'.code);
      case 8: u.addChar('\\'.code); u.addChar('b'.code);
      case 12: u.addChar('\\'.code); u.addChar('f'.code);
      default: u.addChar(c);
      }
    });
    buf.add('"');
    buf.add(u.toString());
    buf.add('"');
  }
  #end

}
private class DynamicWriter {
  static public inline function stringify(v:Dynamic):String
    return haxe.format.JsonPrinter.print(v);
}
#end


package tink.json;

using StringTools;
using tink.CoreApi;

#if !macro
@:genericBuild(tink.json.macros.Macro.buildParser())
#end
class Parser<T> {
  
}

private class SliceData {
  
  public var source(default, null):String;
  public var min(default, null):Int;
  public var max(default, null):Int;
  
  public inline function new(source, min, max) {
    this.source = source;
    this.min = min;
    this.max = max;
  }
}

@:forward
private abstract JsonString(SliceData) from SliceData {

  public function toString():String 
    return 
      if (this.source.indexOf('\\') == -1)
        get();
      else
        haxe.format.JsonParser.parse(this.source.substring(this.min-1, this.max+1));
  
  public inline function get() 
    return this.source.substring(this.min, this.max);
  
        
  public inline function toInt() 
    return Std.parseInt(get());
  
  public inline function toFloat() 
    return Std.parseFloat(get());
    
  @:commutative @:op(a == b) 
  static public inline function equalsString(a:JsonString, b:String):Bool {
    return b.length == (a.max - a.min) && 
      #if nodejs
        (a.source : Dynamic).startsWith(b, a.min);
      #else
        a.source.substring(a.min, a.max) == b;
      #end
  }
    
}

class BasicParser { 
  var source:String;
  var pos:Int;
  var max:Int;
  
  function init(source) { 
     this.source = source;
     this.pos = 0;
     this.max = source.length;
     skipIgnored();
  }
  
  inline function skipIgnored()
    while (pos < max && source.fastCodeAt(pos) < 33) pos++;
  
  #if !macro
  function parseString():JsonString {
    expect('"');
    return slice(skipString(), pos - 1);
  }
  
  function skipString() {
    var start = pos;
    
    while (true)
      switch source.indexOf('"', pos) {
        case -1: 
          
          die('unterminated string', start);
        
        case v:
          
          pos = v + 1;
          
          var p = pos - 2;
          
          while (source.fastCodeAt(p) == '\\'.code) p--;
          if ((p - pos) & 1 == 0) 
            break;
      }
    
    return start;  
  }
    
  static inline function isDigit(char:Int)
    return char < 58 && char > 47;
  
  function parseNumber():JsonString 
    return slice(skipNumber(source.fastCodeAt(pos++)), pos);

	function invalidNumber( start : Int )
		return die("Invalid number ${str.substr(start, pos - start)}", start);
    
  function skipNumber(c:Int) {
    //ripped shamelessly from haxe.format.JsonParser
    var start = pos - 1;
		var minus = c == '-'.code, digit = !minus, zero = c == '0'.code;
		var point = false, e = false, pm = false, end = false;
		while( true ) {
			c = nextChar();
			switch( c ) {
				case '0'.code :
					if (zero && !point) invalidNumber(start);
					if (minus) {
						minus = false; zero = true;
					}
					digit = true;
				case '1'.code,'2'.code,'3'.code,'4'.code,'5'.code,'6'.code,'7'.code,'8'.code,'9'.code :
					if (zero && !point) invalidNumber(start);
					if (minus) minus = false;
					digit = true; zero = false;
				case '.'.code :
					if (minus || point) invalidNumber(start);
					digit = false; point = true;
				case 'e'.code, 'E'.code :
					if (minus || zero || e) invalidNumber(start);//from my understanding of the spec on json.org 0e4 is a valid number
					digit = false; e = true;
				case '+'.code, '-'.code :
					if (!e || pm) invalidNumber(start);
					digit = false; pm = true;
				default :
					if (!digit) invalidNumber(start);
					pos--;
					end = true;
			}
			if (end) break;
		}
    return start;
  }
  
  function slice(from, to):JsonString
    return new SliceData(this.source, from, to);
	
  inline function nextChar() 
		return source.fastCodeAt(pos++);
	    
  function skipValue() 
    switch nextChar() {
      case '{'.code:
        
        if (allow('}'))
          return;
                  
        inline function pair() {
          if (nextChar() != '"'.code)
            die('expected string', pos - 1);
            
          skipString();
          expect(':');
          skipValue();
        }
        
        do {
          pair();
        } while (allow(','));
        
        expect('}', true, false);
        
      case '['.code:
        if (allow(']')) 
          return;
        
        do {
          skipValue();
        } while (allow(','));
        
        expect(']', true, false);
      case '"'.code:
        skipString();
      case 't'.code:
        expect('rue', false, false);
      case 'f'.code:
        expect('alse', false, false);
      case 'n'.code:
        expect('ull', false, false);
      case '.'.code:
        skipNumber('.'.code);
      case v if (isDigit(v)):
        skipNumber(v);
      case invalid: 
        invalidChar(invalid);
    }  
  
  function invalidChar(c:Int) 
    return die('invalid char ${c.hex(2)}', pos - 1);

  function die(s:String, ?pos:Int):Dynamic {
    if (pos == null)
      pos = this.pos;
      
    return new Error('#pos: $pos'+s).throwSelf();
  }
  #end
  
  macro function expect(ethis, s:String, skipBefore:Bool = true, skipAfter:Bool = true) {
    return macro (if (!$ethis.allow($v{s}, $v{skipBefore}, $v{skipAfter})) $ethis.die('Expected $s') else null : tink.json.Parser.ContinueParsing);
  }
  
  macro function allow(ethis, s:String, skipBefore:Bool = true, skipAfter:Bool = true) {
    
    if (s.length == 0)
      throw 'assert';
      
    var ret = macro this.max > this.pos + $v{s.length - 1};
    
    for (i in 0...s.length)
      ret = macro $ret && StringTools.fastCodeAt($ethis.source, $ethis.pos + $v{i}) == $v{s.charCodeAt(i)};
    
    return macro {
      if ($v{skipBefore}) 
        $ethis.skipIgnored();
      if ($ret) {
        $ethis.pos += $v{s.length};
        if ($v{skipAfter}) 
          $ethis.skipIgnored();
        true;
      }
      else false;
    }
  }
  #if !macro    
  function parseBool() 
    return 
      if (this.allow('true')) true;
      else if (this.allow('false')) false;
      else die('expected boolean value');
  #end
  
}

abstract ContinueParsing(Dynamic) {
  @:commutative @:op(a+b)
  @:extern static inline function then<A>(e:ContinueParsing, a:A):A 
    return a;
}
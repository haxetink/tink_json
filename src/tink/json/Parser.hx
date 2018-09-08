package tink.json;

import tink.json.Value;
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

#if js
@:native('JSON')
private extern class StdParser {
  static function parse(s:String):Dynamic;
}
#else
private typedef StdParser = haxe.format.JsonParser;
#end

@:forward
private abstract JsonString(SliceData) from SliceData {

  function contains(s:String)
    return switch this.source.indexOf(s, this.min) {
      case -1: false;
      case outside if (outside > this.max): false;
      case v: true;
    }
  
  public function toString():String 
    return
      if (contains('\\')) 
        StdParser.parse(this.source.substring(this.min - 1, this.max + 1));
      else get();
  
  #if tink_json_compact_code
  @:native('g')
  #else
  inline 
  #end
  public function get() 
    return this.source.substring(this.min, this.max);
        
  public inline function toInt() 
    return Std.parseInt(get());
  
  public inline function toFloat() 
    return Std.parseFloat(get());
    
  @:commutative @:op(a == b) 
  #if tink_json_compact_code
  @:native('e')
  #else
  inline 
  #end
  static public function equalsString(a:JsonString, b:String):Bool {
    return b.length == (a.max - a.min) && 
      #if nodejs
        (a.source : Dynamic).startsWith(b, a.min);
      #else
        a.source.substring(a.min, a.max) == b;
      #end
  }
    
}

#if !macro
@:build(tink.json.macros.Macro.compact())
#end
class BasicParser { 
  
  public var plugins(default, null):Annex<BasicParser>;
  
  var source:String;
  var pos:Int;
  var max:Int;
  
  function new()
    this.plugins = new Annex(this);

  function init(source) { 
     this.source = source;
     this.pos = 0;
     this.max = source.length;
     skipIgnored();
  }
  #if !tink_json_compact_code
  inline 
  #end
  function skipIgnored()
    while (pos < max && source.fastCodeAt(pos) < 33) pos++;
  
  #if !macro
  function parseDynamic():Any {
    var start = pos;
    skipValue();
    return StdParser.parse(this.source.substring(start, pos));
  }


  function parseString():JsonString
    return expect('"', true, false, "string") & parseRestOfString();

  function parseRestOfString():JsonString
    return slice(skipString(), pos - 1);
  
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

  static inline function startsNumber(char:Int)
    return char == '.'.code || char == '-'.code || isDigit(char);
  
  function parseNumber():JsonString 
    return
      if (startsNumber(source.fastCodeAt(pos)))
        doParseNumber();
      else 
        die("number expected");

  function doParseNumber():JsonString 
    return slice(skipNumber(source.fastCodeAt(pos++)), pos);

  function invalidNumber( start : Int )
    return die('Invalid number ${source.substring(start, pos)}', start);
    
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

  function parseSerialized<T>():Serialized<T> {
    var start = pos;
    skipValue();
    return cast source.substring(start, pos);
  }

  function parseValue():Value
    return switch nextChar() {
      case '{'.code:
        var fields = new Array<Named<Value>>();
        if (!allow('}')) {
          inline function pair() {
            if (nextChar() != '"'.code)
              die('expected string', pos - 1);
              
            fields.push(new Named(
              parseRestOfString().toString(),
              expect(':') & parseValue()
            ));
          }
          
          do {
            pair();
          } while (allow(','));
          
          expect('}', true, false);
        }
        
        VObject(fields);

      case '['.code:
        
        var ret = new Array<Value>();
        
        if (!allow(']')) {
          do {
            ret.push(parseValue());
          } while (allow(','));
          expect(']', true, false);
        }
        
        VArray(ret);

      case '"'.code:
        VString(parseRestOfString().toString());
      case 't'.code:
        expect('rue', false, false) & VBool(true);
      case 'f'.code:
        expect('alse', false, false) & VBool(false);
      case 'n'.code:
        expect('ull', false, false) & VNull;
      case char:
        if (startsNumber(char)) {
          pos--;
          VNumber(doParseNumber().toFloat());
        } 
        else invalidChar(char);
    }  

  function skipArray() {
    if (allow(']')) 
      return;
        
    do {
      skipValue();
    } while (allow(','));
        
    expect(']', true, false);  
  }
  
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
        skipArray();
      case '"'.code:
        skipString();
      case 't'.code:
        expect('rue', false, false);
      case 'f'.code:
        expect('alse', false, false);
      case 'n'.code:
        expect('ull', false, false);
      case char: 
        if (startsNumber(char))
          skipNumber(char);
        else
          invalidChar(char);
    }  
  
  function invalidChar(c:Int) 
    return die('invalid char ${c.hex(2)}', pos - 1);

  function die(s:String, ?pos:Int, ?end:Int):Dynamic {
    if (pos == null) {
      end = pos = this.pos;
    }
    else if (end == null)
      end = this.pos;
    
    if (end <= pos) 
      end = pos + 1;
      
    var range = 
      if (end > pos + 1) 'characters $pos - $end';
      else 'character $pos';
    
    function clip(s:String, maxLength:Int, left:Bool)
      return 
        if (s.length > maxLength) 
          if (left)
            '... ' + s.substr(s.length - maxLength);
          else
            s.substr(0, maxLength) + ' ...';
        else 
          s;

    var p:Int = pos + end;
    var center = p >> 1;
    var context = clip(source.substring(0, pos), 20, true) + '  ---->  ' + clip(source.substring(pos, center), 20, false) + clip(source.substring(center, end), 20, true) + '  <----  ' + clip(source.substring(end), 20, false);
            
    return Error.withData(UnprocessableEntity, s+' at $range in $context', { source: source, start: pos, end: end }).throwSelf();
  }
  #end
  
  #if tink_json_compact_code
  function allow(s:String, skipBefore:Bool = true, skipAfter:Bool = true) {
    if (skipBefore) skipIgnored();
    var l = s.length;
    var found = source.substr(pos, l) == s;
    if (found) pos += l;
    if (skipAfter) skipIgnored();
    return found;
  }
  function expect(s:String, skipBefore:Bool = true, skipAfter:Bool = true, ?expected:String):ContinueParsing {
    if (expected == null) expected = s;
    return if (!allow(s, skipBefore, skipAfter)) die('Expected $expected') else null;
  }
  #else
  macro function expect(ethis, s:String, skipBefore:Bool = true, skipAfter:Bool = true, ?expected:String) {
    if (expected == null) expected = s;
    return macro (if (!$ethis.allow($v{s}, $v{skipBefore}, $v{skipAfter})) $ethis.die('Expected $expected') else null : tink.json.Parser.ContinueParsing);
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
  #end
  #if !macro    
  function parseBool() 
    return 
      if (this.allow('true')) true;
      else if (this.allow('false')) false;
      else die('expected boolean value');
  #end
  
}

abstract ContinueParsing(Dynamic) {
  @:commutative @:op(a & b)
  @:extern static inline function then<A>(e:ContinueParsing, a:A):A 
    return a;
}
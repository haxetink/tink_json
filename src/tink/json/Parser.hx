package tink.json;

import haxe.io.*;
import tink.json.Value;
using StringTools;
using tink.CoreApi;

#if !macro
@:genericBuild(tink.json.macros.Macro.buildParser())
#end
class Parser<T> {

}

#if php
private abstract RawData(BytesData) {
  public inline function new(s, setLength) {
    var b = Bytes.ofString(s);
    this = b.getData();
    setLength(b.length);
  }

  public function substring(min:Int, max:Int)
    return Bytes.ofData(this).getString(min, max - min);

  public inline function hasBackslash(min:Int, max:Int)
    return charPos('\\'.code, min, max) != -1;

  public inline function getChar(i:Int)
    return Bytes.fastGet(this, i);

  public function charPos(char:Int, start:Int, end:Int) {
    for (pos in start...end)
      if (getChar(pos) == char) return pos;
    return -1;
  }

  public function hasId(s:String, min:Int, max:Int)
    return substring(min, max) == s;

}

private abstract Char(Int) to Int {
  public inline function new(code:Int)
    this = code;
}
#else
@:forward(substring, length)
private abstract RawData(String) {
  public inline function new(s, setLength) {
    this = s;
    setLength(s.length);
  }

  public function hasBackslash(min:Int, max:Int)
    return switch this.indexOf('\\', min) {
      case -1: false;
      case outside if (outside > max): false;
      case v: true;
    }

  public inline function getChar(i:Int)
    return this.fastCodeAt(i);

  public inline function charPos(char:Char, start:Int, end:Int)
    return this.indexOf(char, start);

  public inline function hasId(s, min, max)
    return
      #if nodejs // perhaps also check for es5/6
        (this : Dynamic).startsWith(s, min);
      #else
        this.substring(min, max) == s;
      #end

}

private abstract Char(String) to String {
  public inline function new(code:Int)
    this = String.fromCharCode(code);
}
#end

private class SliceData {

  public var source(default, null):RawData;
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

  public function toString():String
    return
      if (#if js true #else this.source.hasBackslash(this.min, this.max) #end)
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

  public function toUInt() {
    var ret:UInt = 0;
    var v = get();
    for(i in 0...v.length) ret += Std.parseInt(v.charAt(i)) * Std.int(Math.pow(10, v.length - i - 1));
    return ret;
  }

  public inline function toFloat()
    return Std.parseFloat(get());

  @:commutative @:op(a == b)
  #if tink_json_compact_code
  @:native('e')
  #else
  inline
  #end
  static public function equalsString(a:JsonString, b:String):Bool
    return b.length == (a.max - a.min) &&
      a.source.hasId(b, a.min, a.max);

}

#if !macro
@:build(tink.json.macros.Macro.compact())
#end
class BasicParser {

  public var plugins(default, null):Annex<BasicParser>;

  var source:RawData;
  var pos:Int;
  var max:Int;
  var afterParsing = new Array<Void->Void>();

  function new()
    this.plugins = new Annex(this);

  function init(source) {
    this.pos = 0;
    this.source = new RawData(source, function (m) this.max = m);
    skipIgnored();
  }
  #if !tink_json_compact_code
  inline
  #end
  function skipIgnored()
    while (pos < max && source.getChar(pos) < 33) pos++;

  #if !macro
  function parseDynamic():Any {
    var start = pos;
    skipValue();
    return StdParser.parse(this.source.substring(start, pos));
  }

  static var DBQT = new Char('"'.code);

  function copyFields<T:{}>(target:T, source:T):T {
    #if js
      js.lib.Object.assign(target, source);
    #else
      for (f in Reflect.fields(source))
        Reflect.setField(target, f, Reflect.field(source, f));
    #end
    return target;
  }

  function emptyInstance<T:{}>(cls:Class<T>):T {
    return
      #if js
        js.lib.Object.create(untyped cls.prototype);
      #else
        Type.createEmptyInstance(cls);
      #end
  }

  function parseString():JsonString
    return expect('"', true, false, "string") & parseRestOfString();

  function parseRestOfString():JsonString
    return slice(skipString(), pos - 1);

  function skipString() {
    var start = pos;

    while (true)
      switch source.charPos(DBQT, pos, max) {
        case -1:

          die('unterminated string', start);

        case v:

          pos = v + 1;

          var p = pos - 2;

          while (source.getChar(p) == '\\'.code) p--;
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
      if (startsNumber(source.getChar(pos)))
        doParseNumber();
      else
        die("number expected");

  function doParseNumber():JsonString
    return slice(skipNumber(source.getChar(pos++)), pos);

  function invalidNumber(start:Int)
    return die('Invalid number ${source.substring(start, pos)}', start);

  function skipNumber(c:Int) {
    //ripped shamelessly from haxe.format.JsonParser
    var start = pos - 1;
    var minus = c == '-'.code, digit = !minus, zero = c == '0'.code;
    var point = false, e = false, pm = false, end = false;
    while( pos < max ) {
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
    return source.getChar(pos++);

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

  function die(s:String, pos:Int = -1, end:Int = -1):Dynamic {
    if (pos == -1)
      end = pos = this.pos;
    else if (end == -1)
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

    var center = (pos + end) >> 1;
    var context = clip(source.substring(0, pos), 20, true) + '  ---->  ' + clip(source.substring(pos, center), 20, false) + clip(source.substring(center, end), 20, true) + '  <----  ' + clip(source.substring(end, max), 20, false);

    return Error.withData(UnprocessableEntity, s+' at $range in $context', { source: source, start: pos, end: end }).throwSelf();
  }
  #end

  #if tink_json_compact_code
  function allow(s:String, skipBefore:Bool = true, skipAfter:Bool = true) {
    if (skipBefore) skipIgnored();
    var l = s.length;
    var found = source.substring(pos, l + pos) == s;
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
    return macro (if (!$ethis.allow($v{s}, $v{skipBefore}, $v{skipAfter})) $ethis.die('Expected ' + $v{expected}) else null : tink.json.Parser.ContinueParsing);
  }

  macro function allow(ethis, s:String, skipBefore:Bool = true, skipAfter:Bool = true) {

    if (s.length == 0)
      throw 'assert';

    var ret = macro this.max > this.pos + $v{s.length - 1};

    for (i in 0...s.length)
      ret = macro $ret && $ethis.source.getChar($ethis.pos + $v{i}) == $v{s.charCodeAt(i)};

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
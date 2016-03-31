package tink.json;

import tink.parse.ParserBase;
import tink.parse.StringSlice;
import tink.parse.Char.*;

using StringTools;
using tink.CoreApi;

@:genericBuild(tink.json.Macro.buildParser())
class Parser<T> {
  
}

private abstract JsonString(StringSlice) from StringSlice {
  @:to public function toString():String {
    return haxe.format.JsonParser.parse('"$this"');
  }
  @:to inline function toSlice()
    return this;
}

class BasicParser extends ParserBase<StringSlice, Error> { 
  static var ARRAY:ListSyntax = { end: ']', sep: ',' };
  override function doSkipIgnored() 
    doReadWhile(WHITE);    
  
  function parseString()
    return parseStringWith('"');
  
  function parseNull<A>(parser:Void->A):Null<A>
    return
      if (allow('null')) null;
      else parser();  
      
  function parseBool() 
    return 
      if (allow('true')) true;
      else if (allow('false')) false;
      else die('expected boolean value');
    
  function skipValue() {
    skipIgnored();
    switch source[pos] {
      case '['.code: expect('['); parseList(skipValue, ARRAY);
      case '{'.code: expect('{'); parseObject(function (_) skipValue());
      case '"'.code: parseString();
      case 't'.code, 'f'.code: parseBool();
      case 'n'.code: expect('null');
      case num if (num == '.'.code || DIGIT[num]): parseNumber();
      case v:
        die('Invalid character 0x'+v.hex(2));
    }
  }  
  
  override function makeError(message:String, pos:StringSlice):Error {
    return new Error(message);
  }
  
  function parseObject(parseValue:StringSlice->Void) {
    var start = -1;
    expect('{');
    parseRepeatedly(function () {
      if (start == -1)
        start = this.pos;
      var name = parseString();
      expect(':');
      parseValue(name);
    }, { end: '}', sep: ',' } );
    return start;
  }
  
  override function doMakePos(from:Int, to:Int) {
    return source[from...to];
  }
  
  function parseArray<A>(reader:Void->A) 
    return expect('[') + parseList(reader, ARRAY );    
    
  function parseNumber() {
    var start = pos;
    
    function digits() {
      var start = pos;
      doReadWhile(DIGIT);
      if (start == pos)
        die('at least one digit expected');
    }
    
    function exponent() {
      if (allowHere('e')) {
        allowHere('+') || allowHere('-');
        digits();
      }
      return chomp(start);      
    }
    
    function fraction() {
      digits();
      return exponent();
    }
      
    return
      if (allow('.'))
        fraction();
      else {
        digits();
        
        if (DIGIT[source[pos+1]] && allowHere('.'))
          fraction();
        else
          exponent();
      }
  }
    
  function parseStringWith(quote:StringSlice):JsonString {
    expect(quote);
    var start = pos;
    do {
      upto(quote);
    } while (source[pos - 2] == '\\'.code);
    
    return source[start...pos - 1];
  }
  
}
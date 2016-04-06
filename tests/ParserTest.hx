package;

import haxe.Constraints.IMap;
import haxe.io.Bytes;
import haxe.PosInfos;
import haxe.unit.TestCase;
import haxe.unit.TestStatus;
import tink.core.Error;
import tink.json.Parser;

typedef Foo = { foo:Float, bar:Array<{ flag: Bool, ?buzz:Array<{ word: String }> }> };
typedef Cons<T> = Null<{
  head:T,
  ?tail:Cons<T>
}>;

enum Color {
  Rgb(a:Int, b:Int, c:Int);
  Hsv(hsv:{ hue:Float, saturation:Float, value:Float });
  Hsl(value:{ hue:Float, saturation:Float, lightness:Float });
}

abstract Hitpoints(Int) from Int to Int {
  
}

enum PotionEffect {
  Heals(hp:Hitpoints);
  Restores(mana:Int);
}

enum Item {
  @:json({ type: 'sword' }) Sword(damage:{max:Int});
  @:json({ type: 'shield' }) Shield(shield:{armor:Int});
  @:json({ type: 'staff' }) Staff(block:Float, ?magic:Int);
  Potion(effect:PotionEffect);
}

class ParserTest extends TestCase {
  
  function bytes(a:Array<Int>) {
    var ret = Bytes.alloc(a.length);
    
    for (i in 0...a.length)
      ret.set(i, a[i] & 255);
      
    return ret;
  }
  
  function assertFailure(f:Void->Void) {
    try {
      f();
      throw 'Function did not fail';
    }
    catch (e:TestStatus) {
      
    }
  }
  
  function testStructEq() {
    structEq( { foo: [{ bar: [4] }]}, { foo: [{ bar: [4] }]} );
    assertFailure(function () {
      structEq( { foo: [{ bar: [4] }]}, { foo: [{ bar: [5] }]} );
    });
    
    structEq( { foo: [ 'bar' => [4] ] }, { foo: [ 'bar' => [4] ] } );
    
    assertFailure(function () {
      structEq( { foo: [ 'bar' => 4 ] }, { foo: [ 'bar' => 5 ] } );
    });
        
    structEq( { foo: [ 'bar' => [Staff(400, 20)] ] }, { foo: [ 'bar' => [Staff(400, 20)] ] } );
    
    assertFailure(function () {
      structEq( { foo: [ 'bar' => [Staff(400, 20)] ] }, { foo: [ 'bar' => [Staff(400, 30)] ] } );
    });
    
    structEq(
      { foo: [{ bar: [Date.fromTime(0)] }]}, 
      { foo: [{ bar: [Date.fromTime(0)] }]} 
    );
    
    assertFailure(function () {
      structEq( 
        { foo: [{ bar: [Date.fromTime(4000)] }]}, 
        { foo: [{ bar: [Date.fromTime(5000)] }]} 
      );
    });
    
    structEq( 
      { foo: [{ bar: [bytes([for (i in 0...0x100) i])] }]}, 
      { foo: [{ bar: [bytes([for (i in 0...0x100) i])] }]} 
    );
    
    assertFailure(function () {
      structEq(
        { foo: [ { bar: [bytes([for (i in 0...0xFF) i])] } ] }, 
        { foo: [ { bar: [bytes([for (i in 0...0x100) i])] } ] } 
      );
    });    
  }
  
  function measure<A>(s:String, f:Void->A, ?pos:haxe.PosInfos) {
    function stamp()
      return
        #if java
          Sys.cpuTime();
        #else
          haxe.Timer.stamp();
        #end
        
    var start = stamp();
    var ret = f();
    haxe.Log.trace('$s took ${stamp() - start}', pos);
    return ret;
  }
  /**
  public function testPerformance() {
    var o = {
      blub: [
        { foo: [ { bar: [true] } ] }, 
        { foo: [ { bar: [false] } ] } 
      ]
    };
    //
    for (i in 0...100000)
      haxe.Json.stringify(o);
      
    measure('haxe stringify', function () 
      for (i in 0...10000)
        haxe.Json.stringify(o)
    );
    
    var writer = new tink.json.Writer<{ blub:Array<{ foo: Array<{ bar:Array<Bool> }>}> }>();
    for (i in 0...100000)
      writer.write(o);
      
    measure('tink stringify', function () 
      for (i in 0...10000)
        writer.write(o)
    );
        
    var s = tink.Json.stringify(o);
    
    
    for (i in 0...100000)
      o = haxe.Json.parse(s);
      
    measure('haxe parse', function () 
      for (i in 0...10000)
        o = haxe.Json.parse(s)
    );
    
    var parser = new tink.json.Parser<{ blub:Array<{ foo: Array<{ bar:Array<Bool> }>}> }>();
    for (i in 0...100000)
      parser.parse(s);
    
    measure('tink parse', function () 
      for (i in 0...10000)
        parser.parse(s)
    );
    
    //var parser = new tink.json.Parser<Array<Bool>>();
    //var s = '[true]';
    ////
    //measure('haxe parse', function () 
      //for (i in 0...10000)
        //haxe.format.JsonParser.parse(s)
    //);    
    //
    //measure('tink parse', function () 
      //for (i in 0...10000)
        //parser.parse(s)
    //);    
  }
  /**/
  public function testParser() {
    
    Helper.roundtrip({
      foo: true,
      bar: [
        {
          werg: 'foo',
          fwerlk: [{ baz: 5 }, { baz: 15 }]
        }
      ]
    });
    
    var x: Foo = {
      foo: 4.5,
      bar: [{
        flag: true,
      }, {
        flag: false,
        buzz: [{ word: 'blub' }]
      }]
    }
    
    Helper.roundtrip(x);
    
    var x: { foo:Float } = x;
    
    x = tink.Json.parse(haxe.Json.stringify(x, '  '));
    
    var l:Cons<Int> = {
      head: 4,
      tail: {
        head: 3,
        tail: {
          head: 2
        }
      }
    };
    
    Helper.roundtrip(l);
    
    Helper.roundtrip({
      foo: [
        4 => true,
        5 => false
      ]
    }, true);
    
    Helper.roundtrip({
      foo: ({
        first: 1,
        second: 2
      } : Dynamic<Int>),
      bar: ({
        first: 1,
        second: 2
      } : haxe.DynamicAccess<Int>),       
    });
    
    var equipment = [Sword({max:40}), Staff(.5), Shield({ armor: 50 }), Potion(Heals(30))];
    
    Helper.roundtrip(equipment, true);
    
    structEq([Sword({max:100}), Shield({armor:50})], tink.Json.parse('[{ "type": "sword", "damage": { "max": 100 }},{ "type": "shield", "armor": 50 }]'));
    
    Helper.roundtrip([
      Rgb(128, 100, 80), 
      Hsv({ value: 100.0, saturation: 100.0, hue: 0.0 }), 
      Hsl({ lightness: 100.0, saturation: 100.0, hue: 0.0 })
    ], true);
    
    Helper.roundtrip({
      date: Date.now(),
      bytes: bytes([for (i in 0...0x100) i])
    }, true);
    
  }
  
	function fail( reason:String, ?c : PosInfos ) : Void {
		currentTest.done = true;
    currentTest.success = false;
    currentTest.error   = reason;
    currentTest.posInfos = c;
    throw currentTest;
	}  
  
  function structEq<A>(expected:A, found:A) {
    
    var eType = Type.typeof(expected),
        fType = Type.typeof(found);
    if (!eType.equals(fType))    
      fail('$found should be $eType but is $fType');
    
    assertTrue(true);
    
    switch eType {
      case TNull, TInt, TFloat, TBool, TClass(String):
        assertEquals(expected, found);
      case TFunction:
        throw 'not implemented';
      case TObject:
        for (name in Reflect.fields(expected)) {
          structEq(Reflect.field(expected, name), Reflect.field(found, name));
        }
      case TClass(Array):
        var expected:Array<A> = cast expected,
            found:Array<A> = cast found;
            
        if (expected.length != found.length)
          fail('expected $expected but found $found');
        
        for (i in 0...expected.length)
          structEq(expected[i], found[i]);
          
      case TClass(_) if (Std.is(expected, IMap)):
        var expected = cast (expected, IMap<Dynamic, Dynamic>);
        var found = cast (found, IMap<Dynamic, Dynamic>);
        
        for (k in expected.keys()) {
          structEq(expected.get(k), found.get(k));
        }
        
      case TClass(Date):
        
        var expected:Date = cast expected,
            found:Date = cast found;
        
        if (expected.getTime() != found.getTime())
          fail('expected $expected but found $found');
            
      case TClass(Bytes):
        
        var expected = (cast expected : Bytes).toHex(),
            found = (cast found : Bytes).toHex();
        
        if (expected != found)
          fail('expected $expected but found $found');
            
      case TClass(cl):
        throw 'comparing $cl not implemented';
        
      case TEnum(e):
        
        var expected:EnumValue = cast expected,
            found:EnumValue = cast found;
            
        assertEquals(Type.enumConstructor(expected), Type.enumConstructor(found));
        structEq(Type.enumParameters(expected), Type.enumParameters(found));
      case TUnknown:
        throw 'not implemented';
    }
  }  
}
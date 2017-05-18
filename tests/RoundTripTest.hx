package;

import tink.unit.Assert.*;
import deepequal.DeepEqual.*;
import Types;

using tink.CoreApi;

class RoundTripTest {
  public function new() {}
  
  public function object() {
    return assert(Helper.roundtrip({
      foo: true,
      bar: [
        {
        werg: 'foo',
        fwerlk: [{ baz: 5 }, { baz: 15 }]
        }
      ]
    }));
  }
  
  public function foo() {
    var x: Foo = {
      foo: 4.5,
      bar: [{
        flag: true,
        buzz: null,
      }, {
        flag: false,
        buzz: [{ word: 'blub' }]
      }]
    }
    
    return assert(Helper.roundtrip(x));
  }
  
  public function cons() {
    var l:Cons<Int> = {
      head: 4,
      tail: {
        head: 3,
        tail: {
          head: 2,
          tail: null,
        }
      }
    };
    
    return assert(Helper.roundtrip(l));
  }
  
  public function map() {
    return assert(Helper.roundtrip({
      foo: [
        4 => true,
        5 => false
      ]
    }, true));
  }
  
  public function dynamicAccess() {
    return assert(Helper.roundtrip({
      foo: ({
        first: 1,
        second: 2
      } : Dynamic<Int>),
      bar: ({
        first: 1,
        second: 2
      } : haxe.DynamicAccess<Int>),       
    }));
  }
  
  public function enum1() {
    return assert(Helper.roundtrip([Sword({max:40}), Staff(.5), Shield({ armor: 50 }), Potion(Heals(30))], true));
  }
  
  public function enum2() {
    return assert(Helper.roundtrip([
      Rgb(128, 100, 80), 
      Hsv({ value: 100.0, saturation: 100.0, hue: 0.0 }), 
      Hsl({ lightness: 100.0, saturation: 100.0, hue: 0.0 })
    ], true));
  }
  
  public function others() {
    
    var my:MyAbstract = new MyAbstract([1, 2, 3, 4]);
    var upper:UpperCase = 'test';
    var fakeUpper:UpperCase = cast 'test';
    
    return assert(Helper.roundtrip({
      date: #if cpp new Date(2017,5,5,0,0,0) #else Date.now() #end, // TODO: investigate the precision problem on cpp
      bytes: bytes([for (i in 0...0x100) i]),
      test: new Test('foo'),
      my: my,
      upper: upper,
      fakeUpper: fakeUpper,
    }, true));
  }
  
  
  function bytes(a:Array<Int>) {
    var ret = haxe.io.Bytes.alloc(a.length);
    
    for (i in 0...a.length)
      ret.set(i, a[i] & 255);
      
    return ret;
  }
}
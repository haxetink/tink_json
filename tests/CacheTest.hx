package;

import tink.json.*;
import haxe.ds.Option;

@:asserts
class CacheTest {
  
  public function new() {}
  
  function cls(v:Any):Dynamic
    return Type.getClass(v);
    
  public function writer() {
    var w1 = new Writer<Array<String>>();
    var w2 = new Writer<Array<Int>>();
    var w3 = new Writer<Array<String>>();
    
    asserts.assert(w1 != w3, 'w1 != w3');
    asserts.assert(cls(w1) != cls(w2), 'cls(w1) != cls(w2)');
    asserts.assert(cls(w1) == cls(w3), 'cls(w1) == cls(w3)');
    return asserts.done();
  }
    
  public function parser() {
    var p1 = new Parser<Array<String>>();
    var p2 = new Parser<Array<Int>>();
    var p3 = new Parser<Array<String>>();
  
    asserts.assert(p1 != p3, 'p1 != p3');
    asserts.assert(cls(p1) != cls(p2), 'cls(p1) != cls(p2)');
    asserts.assert(cls(p1) == cls(p3), 'cls(p1) == cls(p3)');
    return asserts.done();
  }
  
  public function nullableWriter() {
    var w1 = new Writer<Null<Date>>();
    var w2 = new Writer<Date>();
    var w3 = new Writer<Null<Date>>();
    
    asserts.assert(w1 != w3, 'w1 != w3');
    asserts.assert(cls(w1) != cls(w2), 'cls(w1) != cls(w2)');
    asserts.assert(cls(w1) == cls(w3), 'cls(w1) == cls(w3)');
    return asserts.done();
  }
  
  public function optionNullableWriter() {
    var w1 = new Writer<{o:Option<Null<Date>>}>();
    var w2 = new Writer<{o:Option<Date>}>();
    var w3 = new Writer<{o:Option<Null<Date>>}>();
    
    asserts.assert(w1 != w3, 'w1 != w3');
    asserts.assert(cls(w1) != cls(w2), 'cls(w1) != cls(w2)');
    asserts.assert(cls(w1) == cls(w3), 'cls(w1) == cls(w3)');
    return asserts.done();
  }
}
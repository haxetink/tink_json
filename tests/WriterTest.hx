package;

import tink.json.Value;
import tink.unit.Assert.*;
import tink.Json.*;
import Types;

using tink.CoreApi;

@:asserts
class WriterTest {
  
  public function new() {}
  
  @:variant(None, '"None"')
  @:variant(Some(1), '{"Some":{"v":1}}')
  public function option(o:Option<Int>, v:String) {
    return assert(stringify(o) == v);
  }
  
  @:variant(None2, '"none"')
  @:variant(Some2({}),  '{"Some2":{}}')
  public function option2(o:Option2, v:String) {
    return assert(stringify(o) == v);
  }
  
  public function emptyAnon() {
    var data:{} = {};
    return assert(stringify(data) == '{}');
  }
  
  public function backSlash() {
    var data:{key:String} = {key: '\\s'};
    return assert(stringify(data) == '{"key":"\\\\s"}');
  }
  
  @:describe('dynamic')
  @:variant({}, '{}')
  @:variant('s', '"s"')
  @:variant(1, '1')
  @:variant(1.2, '1.2')
  @:variant(['a',1.2], '["a",1.2]')
  public function dyn(o:Dynamic, v:String) {
    return assert(stringify(o) == v);
  }

  public function value() {
    var v:Value = VObject([new Named("foo", VArray([VNumber(4)]))]);
    return assert(stringify(v) == '{"foo":[4]}');
  }

  
  public function native() {
    var o:{@:json('default') var _default:Int;} = {_default:1};
    return assert(stringify(o) == '{"default":1}');
  }
  
  public function enumAbstract() {
    return assert(stringify(MyEnumAbstract.A) == '"aaa"');
  }
  
  public function custom() {
    asserts.assert(stringify(new Rocket(100)) == '{"alt":100}');
    asserts.assert(stringify(new Rocket2(100)) == '[100]');
    return asserts.done();
  }
  
  public function custom2() {
    return assert(stringify(new Fruit('apple', .2)) == '{"name":"apple","weight":0.2}');
  }
}

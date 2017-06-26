package;

import tink.json.Value;
import tink.unit.Assert.*;
import tink.Json.*;
import tink.json.*;
import deepequal.DeepEqual.*;
import Types;

using tink.CoreApi;

@:asserts
class ParserTest {
  
  public function new() {}
  
  inline function typedCompare<T>(e:T, a:T) {
    return compare(e, a);
  }
  
  @:variant(None, '"None"')
  @:variant(Some(1), '{"Some":{"v":1}}')
  public function option(o:Option<Int>, v:String) {
    return assert(typedCompare(o, parse(v)));
  }
  
  @:variant(None2, '"none"')
  @:variant(Some2({}),  '{"Some2":{}}')
  public function option2(o:Option2, v:String) {
    return assert(typedCompare(o, parse(v)));
  }
  
  public function emptyAnon() {
    return assert(typedCompare({}, parse('{}')));
  }
  
  public function backSlash() {
    return assert(typedCompare({key: '\\s'}, parse('{"key":"\\\\s"}')));
  }

  public function float() {
    return assert(
      parse(('{ "foo": [1.2345, .123e+6], "bar": true }' : { bar : Bool })).isSuccess() 
        &&
      !parse(('"3.4"' : Float)).isSuccess());
  }
  
  @:describe('dynamic')
  @:variant({}, '{}')
  @:variant('s', '"s"')
  @:variant(1, '1')
  @:variant(1.2, '1.2')
  @:variant(['a',1.2], '["a",1.2]')
  public function dyn(o:Dynamic, v:String) {
    return assert(compare(o, parse(v)));
  }
  
  public function value() {
    var v:Value = VObject([new Named("foo", VArray([VNumber(4)]))]);
    return assert(typedCompare(v, parse('{"foo":[4]}')));
  }
  
  public function enums() {
    return assert(typedCompare([Sword({max:100}), Shield({armor:50})], parse('[{ "type": "sword", "damage": { "max": 100 }},{ "type": "shield", "armor": 50 }]')));
  }
  
  public function native() {
    var o:{@:json('default') var _default:Int;} = parse('{"default":1}');
    return assert(compare({_default:1}, o));
  }
  
  public function enumAbstract() {
    var e:MyEnumAbstract = parse('"aaa"');
    return assert(e == A);
  }
  
  public function invalidEnumAbstract() {
    switch parse(('"abc"':MyEnumAbstract)) {
      case Success(_):
        asserts.fail('Expected failure');
      case Failure(e): 
        asserts.assert(e.code == 422);
        asserts.assert(e.message == 'Unrecognized enum value: abc. Accepted values are: ["aaa","bbb","ccc"]');
    }
    return asserts.done();
  }
  
  public function custom() {
    var f:Fruit = parse('{"name":"apple","weight":0.2}');
    return assert(Std.is(f, Fruit) && f.name == 'apple' && f.weight == .2);
  }
  
  public function date() {
    asserts.assert(parse(('1498484919000':Date)).sure().getTime() == 1498484919000);
    asserts.assert(parse(('0':Date)).sure().getTime() == 0);
    asserts.assert(!parse(('-1':Date)).isSuccess());
    return asserts.done();
  }
  
  public function type() {
    var r = new Parser<{ optional: { ?foo: Int }, mandatory: { foo: Int }}>();
    asserts.assert(r.tryParse('{ "optional": {}, "mandatory": { "foo" : 5 } }').isSuccess());
    asserts.assert(r.tryParse('{ "optional": { "foo": 5 }, "mandatory": { "foo" : 5 } }').isSuccess());
    asserts.assert(!r.tryParse('{ "optional": { "foo": 5 }, "mandatory": {} }').isSuccess());
    return asserts.done();
  }
  
}


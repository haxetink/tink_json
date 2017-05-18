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
    return assert(!parse(('"abc"':MyEnumAbstract)).isSuccess());
  }
  
  public function custom() {
    var f:Fruit = tink.Json.parse(tink.Json.stringify(new Fruit('apple', .2)));
    return assert(f.name == 'apple' && f.weight == .2);
  }
  
  public function type() {
    var r = new Parser<{ optional: { ?foo: Int }, mandatory: { foo: Int }}>();
    asserts.assert(r.tryParse('{ "optional": {}, "mandatory": { "foo" : 5 } }').isSuccess());
    asserts.assert(r.tryParse('{ "optional": { "foo": 5 }, "mandatory": { "foo" : 5 } }').isSuccess());
    asserts.assert(!r.tryParse('{ "optional": { "foo": 5 }, "mandatory": {} }').isSuccess());
    return asserts.done();
  }
  
}


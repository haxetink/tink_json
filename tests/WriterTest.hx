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

  @:describe('Any')
  @:variant({}, '{}')
  @:variant('s', '"s"')
  @:variant(1, '1')
  @:variant(1.2, '1.2')
  @:variant((['a',1.2]:Array<Dynamic>), '["a",1.2]')
  public function any(o:Any, v:String) {
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

  public function vector() {
    var v = new haxe.ds.Vector(3);
    for(i in 0...v.length) v[i] = i;
    return assert(stringify(v) == '[0,1,2]');
  }

  public function enumAbstract() {
    return assert(stringify(MyEnumAbstract.A) == '"aaa"');
  }

  public function optional() {
    var o:{
      ?xxxxx:Int,
      yyyyy:Int,
      ?zzzzz:Int,
    } = { yyyyy: 5 };
    asserts.assert(stringify(o) == '{"yyyyy":5}');
    o.zzzzz = 4;
    asserts.assert(stringify(o) == '{"yyyyy":5,"zzzzz":4}');

    var o:{
      ?xxxxx:Int,
      ?yyyyy:Int,
      ?zzzzz:Int,
    } = {};
    asserts.assert(stringify(o) == '{}');
    o.yyyyy = 5;
    asserts.assert(stringify(o) == '{"yyyyy":5}');

    return asserts.done();
  }

  public function custom() {
    asserts.assert(stringify(new Rocket(100)) == '{"alt":100}');
    asserts.assert(stringify(new Rocket3(100)) == '{"alt":100}');
    asserts.assert(stringify(new Rocket2(100)) == '[100]');
    return asserts.done();
  }

  public function custom2() {
    return assert(stringify(new Fruit('apple', .2)) == '{"name":"apple","weight":0.2}');
  }

  public function pair() {
    var p:Pair<Int, String> = new Pair(1, 'foo');
    asserts.assert(stringify(p) == '[1,"foo"]');
    return asserts.done();
  }
  
  public function either() {
    var e:Either<String, Int> = Left('aa');
    asserts.assert(stringify(e) == '"aa"');
    var e:Either<String, Int> = Right(123);
    asserts.assert(stringify(e) == '123');
    var e:Either<String, {id:String}> = Left('aa');
    asserts.assert(stringify(e) == '"aa"');
    var e:Either<String, {id:String}> = Right({id: 'aa'});
    asserts.assert(stringify(e) == '{"id":"aa"}');
    return asserts.done();
  }

  public function optionInAnon() {
    var e:{o:Option<String>} = {o: null};
    asserts.assert(stringify(e) == '{}');
    var e:{o:Option<String>} = {o: None};
    asserts.assert(stringify(e) == '{}');
    var e:{o:Option<String>} = {o: Some(null)};
    asserts.assert(stringify(e) == '{"o":null}');
    var e:{o:Option<String>} = {o: Some('s')};
    asserts.assert(stringify(e) == '{"o":"s"}');

    var e:{?o:Option<String>} = {};
    asserts.assert(stringify(e) == '{}');
    var e:{?o:Option<String>} = {o: null};
    asserts.assert(stringify(e) == '{}');
    var e:{?o:Option<String>} = {o: None};
    asserts.assert(stringify(e) == '{}');
    var e:{?o:Option<String>} = {o: Some(null)};
    asserts.assert(stringify(e) == '{"o":null}');
    var e:{?o:Option<String>} = {o: Some('s')};
    asserts.assert(stringify(e) == '{"o":"s"}');

    var e:{a:Int, o:Option<String>} = {a:1, o: null};
    asserts.assert(stringify(e) == '{"a":1}');
    var e:{a:Int, o:Option<String>} = {a:1, o: None};
    asserts.assert(stringify(e) == '{"a":1}');
    var e:{a:Int, o:Option<String>} = {a:1, o: Some(null)};
    asserts.assert(stringify(e) == '{"a":1,"o":null}');
    var e:{a:Int, o:Option<String>} = {a:1, o: Some('s')};
    asserts.assert(stringify(e) == '{"a":1,"o":"s"}');

    var e:{z:Int, o:Option<String>} = {z:1, o: null};
    asserts.assert(stringify(e) == '{"z":1}');
    var e:{z:Int, o:Option<String>} = {z:1, o: None};
    asserts.assert(stringify(e) == '{"z":1}');
    var e:{z:Int, o:Option<String>} = {z:1, o: Some(null)};
    asserts.assert(stringify(e) == '{"o":null,"z":1}');
    var e:{z:Int, o:Option<String>} = {z:1, o: Some('s')};
    asserts.assert(stringify(e) == '{"o":"s","z":1}');
    return asserts.done();
  }

  public function nullableDate() {

    var e:{date:Option<Date>} = {date: Some(Date.fromTime(0))};
    asserts.assert(stringify(e) == '{"date":0}');
    var e:{date:Option<Null<Date>>} = {date: Some(null)};
    asserts.assert(stringify(e) == '{"date":null}');

    var e:Date = Date.fromTime(0);
    asserts.assert(stringify(e) == '0');
    var e:Null<Date> = null;
    asserts.assert(stringify(e) == 'null');
    return asserts.done();
  }

  public function argLessEnum() {
    var o:ArgLess = A;
    asserts.assert(stringify(o) == '"a"');
    var o:ArgLess = B;
    asserts.assert(stringify(o) == '{"name":"b"}');
    var o:ArgLess = C(1);
    asserts.assert(stringify(o) == '{"C":{"c":1}}');
    return asserts.done();
  }

  public function uint() {
    var o:{u:UInt} = {u: 1};
    asserts.assert(stringify(o) == '{"u":1}');
    var o:{u:UInt} = {u: 0x80000000};
    asserts.assert(stringify(o) == '{"u":2147483648}');
    var u:UInt = 0x7fffffff;
    u = u + 1;
    var o:{u:UInt} = {u: u};
    asserts.assert(stringify(o) == '{"u":2147483648}');
    return asserts.done();
  }
  
  public function enumAbstractKey() {
    asserts.assert(stringify(EnumAbstractStringKey.A) == '{"type":"aaa"}');
    asserts.assert(stringify(EnumAbstractStringKey.B('foo')) == '{"type":"bbb","v":"foo"}');
    asserts.assert(stringify(EnumAbstractIntKey.A) == '{"type":1}');
    asserts.assert(stringify(EnumAbstractIntKey.B('foo')) == '{"type":2,"v":"foo"}');
    return asserts.done();
  }
  
  public function privateEnumAbstract() {
    asserts.assert(stringify(VeryPrivate.A) == '0');
    asserts.assert(stringify({foo:VeryPrivate.B}) == '{"foo":1}');
    return asserts.done();
  }

  public function testIssue67() {

    var l:{ foo: Lazy<Int> } = { foo: function () return 42 };

    var s = tink.Json.stringify(l);
    asserts.assert(s == '{"foo":42}');

    return asserts.done();
  }

  public function testIssue48() {
    var o:{ foo: Opacity } = { foo: 0.5 };
    asserts.assert(tink.Json.stringify(o) == '{"foo":0.5}');
    return asserts.done();
  }
}

abstract Opacity(Float) from Float to Float {
  @:to public function toString():String {
    return 'huh?';
  }
}

private enum abstract VeryPrivate(Int) {
  var A = 0;
  var B = 1;
}
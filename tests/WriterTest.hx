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
    return assert(tink.Json.stringify(data) == '{}');
  }
  
  public function backSlash() {
    var data:{key:String} = {key: '\\s'};
    return assert(stringify(data) == '{"key":"\\\\s"}');
  }
  
  @:describe('dynamic')
  @:variant({}, '{}')
  public function dyn(o:Dynamic, v:String) {
    return assert(stringify(o) == v);
  }

  public function value() {
    var v:Value = VObject([new Named("foo", VArray([VNumber(4)]))]);
    return assert(stringify(v) == '{"foo":[4]}');
  }

  public function custom() {
    asserts.assert(stringify(new Rocket(100)) == '{"alt":100}');
    asserts.assert(stringify(new Rocket2(100)) == '[100]');
    return asserts.done();
  }
  
}

class RocketWriter {
  public function new(v:Dynamic) {}
  public function prepare(r:Rocket) {
    return { alt: r.altitude };
  }
}

class RocketWriter2 {
  public function new(v:Dynamic) {}
  public function prepare(r:Rocket) {
    return VArray([VNumber(r.altitude)]);
  }
}

@:jsonStringify(WriterTest.RocketWriter2)
abstract Rocket2(Rocket) from Rocket to Rocket {
  public inline function new(alt) this = new Rocket(alt);
}

@:jsonStringify(WriterTest.RocketWriter)
class Rocket {
  public var altitude(default, null):Float;
  public function new(altitude)
    this.altitude = altitude;
}

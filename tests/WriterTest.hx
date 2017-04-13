package;

import haxe.unit.TestCase;
import tink.json.Value;
import tink.Json;

using tink.CoreApi;


class WriterTest extends TestCase {
  
  function testEmptyEnum() {
    var o:Option<Int> = None;
    assertEquals('"None"', tink.Json.stringify(o));
    assertEquals('"none"', tink.Json.stringify(Option2.None2));
    assertEquals('{"Some2":{}}', tink.Json.stringify(Option2.Some2({})));
    o = Some(1);
    assertEquals('{"Some":{"v":1}}', tink.Json.stringify(o));
  }
  
  function testEmptyAnon() {
    var data:{} = {};
    assertEquals('{}', tink.Json.stringify(data));
  }
  
  function testBackSlash() {
    var data:{key:String} = {key: '\\s'};
    var s = tink.Json.stringify(data);
    assertEquals('{"key":"\\\\s"}', s);
    data = tink.Json.parse(s);
    assertEquals('\\s', data.key);
  }

  function testDynamic() {
    var o:Dynamic = {}
    assertEquals('{}', tink.Json.stringify(o));
  }

  function testValue() {
    var v:Value = VObject([new Named("foo", VArray([VNumber(4)]))]);
    assertEquals('{"foo":[4]}', tink.Json.stringify(v));
  }

  function testCustom() {
    assertEquals('{"alt":100}', tink.Json.stringify(new Rocket(100)));
    assertEquals('[100]', tink.Json.stringify(new Rocket2(100)));
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


import tink.json.*;
import tink.Json.*;
@:asserts
class CachedTest {
  public function new() {}
  public function write() {

    var data:Data = {
      var o = { foo: 42 };
      { x: o, y: o }
    }

    asserts.assert(stringify(data) == '{"x":{"foo":42},"y":0}');
    asserts.assert(stringify(data) == '{"x":{"foo":42},"y":0}');

    var w = new tink.json.Writer<Data>();

    asserts.assert(w.write(data) == '{"x":{"foo":42},"y":0}');
    asserts.assert(w.write(data) == '{"x":0,"y":0}');

    data = parse('{"x":{"foo":42},"y":0}');
    asserts.assert(data.x == data.y);

    var p = new tink.json.Parser<Data>();

    data = p.parse('{"x":{"foo":42},"y":0}');
    asserts.assert(data.x == data.y);

    data = p.parse('{"x":{"foo":42},"y":0}');
    asserts.assert(data.x != data.y);

    data = p.parse('{"x":0,"y":0}');
    asserts.assert(data.x == data.y);

    data = p.parse('{"x":1,"y":1}');
    asserts.assert(data.x == data.y);

    asserts.assert(p.tryParse('{"x":2,"y":2}').match(Failure(_)));

    return asserts.done();
  }
}

private typedef Data = {
  var x:Cached<{ foo: Int }>;
  var y:Cached<{ foo: Int }>;
}
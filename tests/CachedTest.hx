
import tink.json.*;
import tink.Json.*;
@:asserts
class CachedTest {
  public function new() {}
  public function simple() {

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

  public function circular() {
    var c:Circular = { ref: null };
    c.ref = c;
    c = parse(stringify(c));
    asserts.assert(c.ref == c);

    var c:Cached<CircularInst> = new CircularInst();
    c = parse(stringify(c));
    asserts.assert(c.ref == c);
    return asserts.done();
  }
}

private typedef Circular = Cached<{ ref:Circular }>;

@:jsonStringify(c -> { ref: (c:tink.json.Cached<CachedTest.CircularInst>)})
@:jsonParse((c:{ ref: tink.json.Cached<CachedTest.CircularInst>}) -> new CachedTest.CircularInst(c.ref))
class CircularInst {
  public var ref:CircularInst;
  public function new(?ref) {
    this.ref = switch ref {
      case null: this;
      case v: v;
    }
  }
}

private typedef Data = {
  var x:Cached<{ foo: Int }>;
  var y:Cached<{ foo: Int }>;
}
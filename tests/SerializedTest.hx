package;

import tink.Json.*;
import tink.json.Serialized;

@:asserts
class SerializedTest {

  public function new() {}

  public function read() {
    var s:Serialized<{ foo: Int }> = cast '{"foo":5}';
    asserts.assert(s.parse().foo == 5);
    return asserts.done();
  }

  public function write() {
    var s:Serialized<{ foo: Int }> = cast '{"foo":5}';
    var o = { bar: s };
    asserts.assert(stringify(o) == '{"bar":$s}');
    s = { foo: 5 };
    return asserts.done();
  }

  public function roundtrip() {
    var s:Serialized<{ foo: Int }> = cast '{"foo":5}';
    var o = { bar: s };
    o = parse(stringify(o));
    asserts.assert(o.bar == s);
    return asserts.done();
  }
}
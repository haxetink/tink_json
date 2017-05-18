package;

import tink.unit.Assert.*;
import tink.Json.*;
import tink.json.Serialized;

class SerializedTest {
	
	public function new() {}
	
	public function read() {
		var s:Serialized<{ foo: Int }> = cast '{"foo":5}';
		return assert(s.parse().foo == 5);
	}
	
	public function write() {
		var s:Serialized<{ foo: Int }> = cast '{"foo":5}';
		var o = { bar: s };
		return assert(stringify(o) == '{"bar":$s}');
	}
	
	public function roundtrip() {
		var s:Serialized<{ foo: Int }> = cast '{"foo":5}';
		var o = { bar: s };
		o = parse(stringify(o));
		return assert(o.bar == s);
	}
}
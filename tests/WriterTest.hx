package;

import haxe.unit.TestCase;
import tink.Json;

using tink.CoreApi;


class WriterTest extends TestCase {
  
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
  
}

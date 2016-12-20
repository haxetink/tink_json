package;

import haxe.unit.TestCase;
import tink.Json;

using tink.CoreApi;


class WriterTest extends TestCase {
  
  function testEmptyAnon() {
    var data:{} = {};
    assertEquals('{}', tink.Json.stringify(data));
  }
  
}
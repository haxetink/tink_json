package;

import haxe.unit.TestCase;
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
    var data:{dyn:Dynamic} = {dyn: 1};
    assertEquals('{"dyn":1}', tink.Json.stringify(data));
    var data:{dyn:Dynamic} = {dyn: 'a'};
    assertEquals('{"dyn":"a"}', tink.Json.stringify(data));
    var data:{array:Array<Dynamic>} = {array: [1, 'a', true]};
    assertEquals('{"array":[1,"a",true]}', tink.Json.stringify(data));
  }
  
}

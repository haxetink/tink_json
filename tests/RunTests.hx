package;

import tink.testrunner.*;
import tink.unit.*;

class RunTests {

  static function main() {
    //var o:{ foo: haxe.ds.Option<Null<Int>> } = tink.Json.parse('{}');
    Runner.run(TestBatch.make([
      new ParserTest(),
    //   new WriterTest(),
    //   new RoundTripTest(),
    //   new SerializedTest(),
    //   new CacheTest(),
    ])).handle(Runner.exit);
  }
  
}
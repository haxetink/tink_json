package;

import tink.testrunner.*;
import tink.unit.*;

using tink.CoreApi;

class RunTests {

  static function main() {
    // var o:{fo:Int} = tink.Json.parse('{"fo":123}');
    Runner.run(TestBatch.make([
      new CachedTest(),
      new ParserTest(),
      new WriterTest(),
      new RoundTripTest(),
      new SerializedTest(),
      new CacheTest(),
    ])).handle(Runner.exit);
  }

}
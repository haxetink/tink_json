package;

import tink.testrunner.*;
import tink.unit.*;

class RunTests {

  static function main() {
    Runner.run(TestBatch.make([
      new ParserTest(),
      new WriterTest(),
      new RoundTripTest(),
      new SerializedTest(),
      new CacheTest(),
    ])).handle(Runner.exit);
  }
  
}
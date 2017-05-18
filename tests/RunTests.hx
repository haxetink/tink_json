package;

import tink.testrunner.*;
import tink.unit.*;

class RunTests {

  static function main() {
    Runner.run(TestBatch.make([
      new WriterTest(),
      new RoundTripTest(),
    ])).handle(Runner.exit);
  }
  
}
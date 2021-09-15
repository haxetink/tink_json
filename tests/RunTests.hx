package;

import tink.testrunner.*;
import tink.unit.*;

using tink.CoreApi;

class RunTests {

  static function main() {
    Runner.run(TestBatch.make([
      new CachedTest(),
      new ParserTest(),
      new WriterTest(),
      new RoundTripTest(),
      new SerializedTest(),
      new CacheTest(),
      // jvm: IO.Overflow("write_ui16") https://github.com/HaxeFoundation/haxe/issues/9654
      // neko: Haxe compiler Stack overflow
      // python: take too much time to compile
      // lua: more than 200 local variables
      #if !(jvm || neko || python || lua)
      new T57Test(),
      #end
    ])).handle(Runner.exit);
  }

}
package;

import haxe.unit.TestRunner;

class RunTests {

  static function main() {
    var t = new TestRunner();
    t.add(new ParserTest());
    t.add(new WriterTest());
    travix.Logger.exit(
      if (t.run()) 0
      else 500
    );
  }
  
}
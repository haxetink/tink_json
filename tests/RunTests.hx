package;
import haxe.unit.TestRunner;

class RunTests {

  static function main() {
    var t = new TestRunner();
    t.add(new ParserTest());
    t.run();
  }
  
}
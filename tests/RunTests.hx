package;

import haxe.unit.TestRunner;

#if flash
typedef Sys = flash.system.System;
#end

class RunTests {

  static function main() {
    var t = new TestRunner();
    t.add(new ParserTest());
    Sys.exit(
      if (t.run()) 0
      else 500
    );
  }
  
}
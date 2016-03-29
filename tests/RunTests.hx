package;

import haxe.unit.TestRunner;

#if flash
typedef Sys = flash.system.System;
#end

class RunTests {

  static function main() {
    var t = new TestRunner();
    t.add(new ParserTest());
    if (!t.run())
      Sys.exit(500);
  }
  
}
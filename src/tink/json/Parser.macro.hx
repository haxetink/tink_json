package tink.json;

class BasicParser {
  static function expect(ethis, s:String, skipBefore:Bool = true, skipAfter:Bool = true, ?expected:String) {
    if (expected == null) expected = s;
    return macro (if (!$ethis.allow($v{s}, $v{skipBefore}, $v{skipAfter})) $ethis.die('Expected ' + $v{expected}) else null : tink.json.Parser.ContinueParsing);
  }

  static function allow(ethis, s:String, skipBefore:Bool = true, skipAfter:Bool = true) {

    if (s.length == 0)
      throw 'assert';

    var ret = macro this.max > this.pos + $v{s.length - 1};

    for (i in 0...s.length)
      ret = macro $ret && $ethis.source.getChar($ethis.pos + $v{i}) == $v{s.charCodeAt(i)};

    return macro {
      if ($v{skipBefore})
        $ethis.skipIgnored();
      if ($ret) {
        $ethis.pos += $v{s.length};
        if ($v{skipAfter})
          $ethis.skipIgnored();
        true;
      }
      else false;
    }
  }
}
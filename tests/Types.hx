package;

import tink.json.Representation;

enum Option2 {
  @:json("none") None2;
  Some2(some2:{});
}

typedef Foo = { foo:Float, bar:Array<{ flag: Bool, ?buzz:Array<{ word: String }> }> };
typedef Cons<T> = Null<{
  head:T,
  ?tail:Cons<T>
}>;

enum Color {
  Rgb(a:Int, b:Int, c:Int);
  Hsv(hsv:{ hue:Float, saturation:Float, value:Float });
  Hsl(value:{ hue:Float, saturation:Float, lightness:Float });
}

abstract Hitpoints(Int) from Int to Int {
  
}

enum PotionEffect {
  Heals(hp:Hitpoints);
  Restores(mana:Int);
}

enum Item {
  @:json({ type: 'sword' }) Sword(damage:{max:Int});
  @:json({ type: 'shield' }) Shield(shield:{armor:Int});
  @:json({ type: 'staff' }) Staff(block:Float, ?magic:Int);
  Potion(effect:PotionEffect);
}

class FruitParser {
  public function new(_) {}

  public function parse(o) 
    return new Fruit(o.name, o.weight);
}

@:jsonParse(Types.FruitParser)
class Fruit {
  public var name(default, null):String;
  public var weight(default, null):Float;
  public function new(name, weight) {
    this.name = name;
    this.weight = weight;
  }
}

abstract Test(String) {
  
  public function new(s)
    this = s;
  
  @:to function toRepresentation():Representation<String> 
    return new Representation(this);
    
  @:from static function ofRepresentation(r:Representation<String>):Test
    return new Test(r.get());
}

abstract UpperCase(String) {
  
  inline function new(v) this = v;
  
  @:to function toRepresentation():Representation<String> 
    return new Representation(this);
    
  @:from static function ofRepresentation(rep:Representation<String>)
    return new UpperCase(rep.get());
  
  @:from static function ofString(s:String)
    return new UpperCase(s.toUpperCase());
}

abstract MyAbstract(Iterable<Int>) {
  
  public inline function new(vec) this = vec;
  
  @:from static function ofRepresentation(rep:Representation<Array<Int>>)
    return new MyAbstract(rep.get());
  
  @:to function toRepresentation():Representation<Array<Int>> 
    return new Representation(Lambda.array(this));
}

@:enum
abstract MyEnumAbstract(String) {
  var A = 'aaa';
  var B = 'bbb';
  var C = 'ccc';
}
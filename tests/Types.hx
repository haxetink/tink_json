package;

import tink.json.Representation;
import tink.json.Value;

enum Option2 {
  @:json("none") None2;
  Some2(some2:{});
}

typedef Foo = { foo:Float, bar:Array<{ flag: Bool, ?buzz:Array<{ word: String }> }> };
typedef Cons<T> = Null<{
  head:T,
  ?tail:Cons<T>
}>;

typedef VarChar<@:const L> = String;

typedef Input = {
  a: VarChar<255>
}

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
  @:json({ type: 'cape' }) Cape(color:Null<String>);
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

@:forward
abstract Contraption({ foo: Int }) from { foo: Int } to { foo: Int } {
  @:from static function ofRepresentation(rep:Representation<Array<Int>>):Contraption
    return { foo: rep.get()[0] };

  @:to function toRepresentation():Representation<Array<Int>>
    return new Representation([this.foo]);
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


class RocketWriter {
  public function new(v:Dynamic) {}
  public function prepare(r:Rocket) {
    return { alt: r.altitude };
  }
}

class RocketWriter2 {
  public function new(v:tink.json.Writer.BasicWriter) {}
  public function prepare(r:Rocket) {
    return VArray([VNumber(r.altitude)]);
  }
}

@:jsonParse(function (o) return new Types.Rocket(o.alt))
@:jsonStringify(function (r) return { alt: r.altitude })
@:forward
abstract Rocket3(Rocket) from Rocket to Rocket {
  public inline function new(alt) this = new Rocket(alt);
}


@:jsonStringify(Types.RocketWriter2)
@:forward
abstract Rocket2(Rocket) from Rocket to Rocket {
  public inline function new(alt) this = new Rocket(alt);
}

@:jsonStringify((_:Types.RocketWriter))
class Rocket {
  public var altitude(default, null):Float;
  public function new(altitude)
    this.altitude = altitude;
}

enum InlineConflictType {
  A(a:{type:String});
  B(b:{type:Int});
  C(c:{?type:String});
  D(d:{type:Null<Int>});
}

enum TaggedInlineConflictType {
  @:json({kind:'a'}) A(a:{type:String});
  @:json({kind:'b'}) B(b:{type:Int});
  @:json({kind:'c'}) C(c:{?type:String});
  @:json({kind:'d'}) D(d:{type:Null<Int>});
}

enum ConflictType {
  A(type:String);
  B(type:Int);
}

enum TaggedConflictType {
  @:json({kind:'a'}) A(type:String);
  @:json({kind:'b'}) B(type:Int);
}

enum ArgLess {
  @:json('a') A;
  @:json({name: 'b'}) B;
  C(c:Int);
}

#if haxe4
enum Content {
	Opt(opt:OptionalFinal);
}

typedef OptionalFinal = {
  @:optional final i:Int;
}
#end

@:enum
abstract MyEnumAbstractInt(Int) {
  var A = 1;
  var B = 2;
  var C = 3;
}

enum EnumAbstractStringKey {
  @:json({type: Types.MyEnumAbstract.A}) A;
  @:json({type: Types.MyEnumAbstract.B}) B(v:String);
}
enum EnumAbstractIntKey {
  @:json({type: Types.MyEnumAbstractInt.A}) A;
  @:json({type: Types.MyEnumAbstractInt.B}) B(v:String);
}

enum RenameConstructor {
  @:json('a') A(v:Int);
  @:json('b') B(b:{v:String});
}

enum abstract IntAbstract(Int) {
  var A = 1;
}

@:jsonStringify(id -> (id : String))
@:jsonParse(id -> Types.MacroFrom.make(id).sure())
abstract MacroFrom(String) to String {
	inline function new(v)
		this = v;

	public static function make(v:String):tink.core.Outcome<MacroFrom, tink.core.Error> {
		return Success(new MacroFrom(v));
	}
	
	@:from
	public static macro function fromExpr(e:haxe.macro.Expr);
}


@:jsonStringify(v -> (cast v:Float))
@:jsonParse((v:Float) -> new Types.NotFloat(v))
abstract NotFloat(Float) {
  public inline function new(v) this = v;
  public inline function toFloat() return this;
}
package;

import tink.Json;
import tink.json.Representation;
import Types.Contraption;

using tink.CoreApi;

@:asserts
class NullableRepresentationTest {
  public function new() {}

  public function numeric() {
    asserts.assert(Json.parse(('null':Null<NumberId<String>>)).match(Success(null)));
    asserts.assert(Json.parse(('42':Null<NumberId<String>>)).sure() == 42);
    var empty:Null<NumberId<String>> = null;
    var present:Null<NumberId<String>> = new NumberId(42);
    asserts.assert(Json.stringify(empty) == 'null');
    asserts.assert(Json.stringify(present) == '42');
    asserts.assert(Json.parse(('null':NumberId<String>)).match(Failure(_)));
    return asserts.done();
  }

  public function arraysAndAliases() {
    var ids:Array<NullableId> = Json.parse('[null,42]');
    asserts.assert(ids.length == 2 && ids[0] == null && ids[1] == 42);
    asserts.assert(Json.stringify(ids) == '[null,42]');
    var nested:{id:NullableId, ?optionalId:NullableId} = Json.parse('{"id":null,"optionalId":null}');
    var missing:{id:NullableId, ?optionalId:NullableId} = Json.parse('{"id":42}');
    asserts.assert(nested.id == null && nested.optionalId == null);
    asserts.assert(missing.id == 42 && missing.optionalId == null);
    var restored:{id:NullableId, ?optionalId:NullableId} = Json.parse(Json.stringify(nested));
    asserts.assert(restored.id == null && restored.optionalId == null);
    return asserts.done();
  }

  public function objectRepresentation() {
    asserts.assert(Json.parse(('null':Null<Contraption>)).match(Success(null)));
    var empty:Null<Contraption> = null;
    asserts.assert(Error.catchExceptions(() -> (Json.stringify(empty):String)).match(Success('null')));
    var present:Null<Contraption> = {foo: 12};
    asserts.assert(Json.stringify(present) == '[12]');
    var restored:Null<Contraption> = Json.parse('[12]');
    asserts.assert(restored.foo == 12);
    return asserts.done();
  }
}

private typedef NullableId = Null<NumberId<String>>;

private abstract NumberId<T>(Int) to Int {
  public inline function new(value:Int)
    this = value;

  @:from static inline function fromRepresentation<T>(value:Representation<Int>):NumberId<T>
    return new NumberId(value.get());

  @:to inline function toRepresentation():Representation<Int>
    return new Representation(this);
}

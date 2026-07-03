package tink.json;

@:deprecated('use @:jsonParse and @:jsonStringify instead')
abstract Representation<T>(T) {

  public function get():T
    return this;

  public inline function new(v:T)
    this = v;

  static public function of<A>(v:Representation<A>)
    return v;
}
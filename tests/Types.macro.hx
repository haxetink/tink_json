package;

abstract MacroFrom(Dynamic) {
	public static macro function fromExpr(e:haxe.macro.Expr) {
		return macro ($e:Types.MacroFrom);
	}
}
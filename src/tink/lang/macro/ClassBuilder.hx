package tink.lang.macro;
import tink.macro.build.MemberTransformer;

/**
 * ...
 * @author back2dos
 */

@:macro class ClassBuilder {
	static public function buildFields():Array<haxe.macro.Expr.Field> {
		return new MemberTransformer().build(PLUGINS);
	}
	static var PLUGINS = [
		Init.process,
		Forward.process,
		PropBuilder.process,
	];	
}
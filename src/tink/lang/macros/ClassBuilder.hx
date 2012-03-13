package tink.lang.macros;
import tink.macro.build.MemberTransformer;
import tink.reactive.bindings.macros.BindableProperties;

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
		#if tink_reactive BindableProperties.make, #end //probably shouldn't be here but it's very convenient for now
	];	
}
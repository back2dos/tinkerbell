package tink.lang.macros;

import haxe.macro.Context;
import tink.macro.build.MemberTransformer;

/**
 * ...
 * @author back2dos
 */

class ClassBuilder {
	@:macro static public function buildFields():Array<haxe.macro.Expr.Field> {
		return new MemberTransformer().build(PLUGINS);
	}
	static function noBindings(ctx:ClassBuildContext) {
		#if debug
			for (m in ctx.members)
				switch (m.extractMeta(':bindable')) {
					case Success(tag): 
						Context.warning('you seem to be wanting to use bindings but don\'t use -lib tink_reactive', tag.pos);
					default: 
				}
		#end
	}
	#if macro
		static var PLUGINS = [
			Init.process,
			Forward.process,
			PropBuilder.process,
			#if tink_reactive //probably shouldn't be here but it's very convenient for now
				tink.reactive.bindings.macros.BindableProperties.make
			#else
				noBindings
			#end,
		];	
	#end
}
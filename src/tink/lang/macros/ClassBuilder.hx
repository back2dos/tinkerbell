package tink.lang.macros;

import haxe.macro.Context;
import tink.macro.build.MemberTransformer;
using tink.macro.tools.MacroTools;
/**
 * ...
 * @author back2dos
 */

class ClassBuilder {
	@:macro static public function buildFields():Array<haxe.macro.Expr.Field> {
		return new MemberTransformer(Context.getLocalClass().get().meta.get().getValues(':verbose').length > 0).build(PLUGINS);
	}
	static function noBindings(ctx:ClassBuildContext) {
		#if debug
			var bindable = [':bindable', ':cache', ':signal'];
			for (m in ctx.members)
				for (tag in bindable)
					switch (m.extractMeta(tag)) {
						case Success(tag): 
							Context.warning('you seem to be wanting to use bindings/signals but don\'t use -lib tink_reactive', tag.pos);
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
				tink.reactive.bindings.macros.BindableProperties.make,
				tink.reactive.signals.macros.SignalBuilder.make
			#else
				noBindings
			#end
		];	
	#end
}
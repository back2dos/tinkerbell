package tink.lang.macros;

#if macro
	import haxe.macro.Context;
	import haxe.macro.Expr;
	import tink.lang.macros.loops.LoopSugar;
	import tink.macro.build.MemberTransformer;
	using tink.macro.tools.MacroTools;
	using haxe.macro.ExprTools;
#end

class ClassBuilder {
	macro static public function buildFields():Array<Field> 
		return 
			new MemberTransformer(Context.getLocalClass().get().meta.get().getValues(':verbose').length > 0).build(PLUGINS);
	
	#if macro
		static function noBindings(ctx:ClassBuildContext) {
			#if debug
				var bindable = [':bindable', ':cache', ':signal'];
				for (m in ctx.members)
					for (tag in bindable)
						switch (m.extractMeta(tag)) {
							case Success(tag): 
								Context.warning('you seem to be wanting to use bindings/signals but don\'t use -lib (tink_reactive || !tink_core)', tag.pos);
							default: 
						}
			#end
		}
		static function simpleSugar(rule:Expr->Expr, ?outsideIn = false) {
			function transform(e:Expr) {
				return switch (e.expr) {
					case EMeta( { name: ':diet' }, _): e;
					default: 
						if (outsideIn) 
							rule(e).map(transform);
						else 
							rule(e.map(transform));
				}
			}
			return syntax(transform);
		}
			
		static function syntax(rule:Expr->Expr) 
			return function (ctx:ClassBuildContext) {
				function transform(f:Function)
					if (f.expr != null)
						f.expr = rule(f.expr);
				ctx.getCtor().onGenerate(transform);
				for (m in ctx.members)
					switch (m.getFunction()) {
						case Success(f): transform(f);
						default:
					}
			}
		//TODO: it seems a little monolithic to yank all plugins here
		static public var PLUGINS = [
			#if (tink_reactive || !tink_core) 
				tink.reactive.signals.macros.SignalBuilder.make,
			#end
			Init.process,
			Forward.process,
			PropBuilder.process,
			#if (tink_reactive || !tink_core)
				tink.reactive.bindings.macros.BindableProperties.make,
			#else
				noBindings,
			#end
			syntax(Pipelining.shortBind),
			simpleSugar(Pipelining.transform, true),
			PartialImpl.process,
			#if (tink_reactive || !tink_core)
				simpleSugar(tink.reactive.signals.macros.SignalSugar.with),
			#end
			simpleSugar(LoopSugar.comprehension),
			#if (tink_reactive || !tink_core)
				simpleSugar(tink.reactive.signals.macros.SignalSugar.on),
				simpleSugar(tink.reactive.signals.macros.SignalSugar.when),
			#end
			simpleSugar(LoopSugar.transformLoop)
		];	
	#end
}
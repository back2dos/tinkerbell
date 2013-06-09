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
				return 
					if (e == null || e.expr == null) e;
					else 
						switch (e.expr) {
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
					switch m.kind {
						case FFun(f): transform(f);
						case FProp(_, _, _, e), FVar(_, e): 
							if (e != null)
								e.expr = rule(e).expr;//RAPTORS
					}
			}

		//TODO: it seems a little monolithic to yank all plugins here
		static public var PLUGINS = [
			simpleSugar(LoopSugar.fold),
			//simpleSugar(LoopSugar.kv),
			#if (tink_reactive || !tink_core) 
				tink.reactive.signals.macros.SignalBuilder.make,
				tink.reactive.bindings.macros.BindableProperties.cache,
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
			
			simpleSugar(function (e) return switch e {
				case macro @in($delta) $handler:
					return ECheckType(
						(macro @:pos(e.pos) haxe.Timer.delay($handler, Std.int($delta * 1000)).stop),
						macro : tink.core.types.Callback.CallbackLink
					).at(e.pos);
				default: e;				
			}),
			
			simpleSugar(ShortLambda.process),
			simpleSugar(ShortLambda.postfix),
		
			
			simpleSugar(Dispatch.normalize),
			simpleSugar(Dispatch.with),
			simpleSugar(Dispatch.on),
			
			simpleSugar(function (e) return switch e { 
				case (macro $val || if ($x) $def else $none)
					,(macro $val | if ($x) $def else $none) if (none == null):
					macro @:pos(e.pos) {
						var ___val = $val;
						(___val == $x ? $def : ___val);
					}
				default: e;
			}),
			simpleSugar(Pipelining.transform, true),
			simpleSugar(tink.markup.formats.Fast.build),
			simpleSugar(tink.markup.formats.Dom.build),
			simpleSugar(DevTools.log, true),
			simpleSugar(DevTools.measure),
			simpleSugar(DevTools.explain),
			PartialImpl.process,
			#if (tink_reactive || !tink_core)
				//simpleSugar(tink.reactive.signals.macros.SignalSugar.with),
			#end
			simpleSugar(LoopSugar.comprehension),
			#if (tink_reactive || !tink_core)
				//simpleSugar(tink.reactive.signals.macros.SignalSugar.on),
			#end
			simpleSugar(LoopSugar.transformLoop),
		];	
	#end
}
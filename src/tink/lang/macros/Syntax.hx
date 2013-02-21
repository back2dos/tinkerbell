package tink.lang.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import tink.markup.formats.Fast;

import tink.lang.macros.loops.LoopSugar;
import tink.macro.build.MemberTransformer;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

typedef Rule = Expr->Expr;

class Syntax {
	static var rules:Array<Array<Rule>> = [
		[
			#if tink_reactive
				tink.reactive.signals.macros.SignalSugar.with,
			#end
			LoopSugar.comprehension
		],
		[
			#if tink_reactive
				tink.reactive.signals.macros.SignalSugar.on,
				tink.reactive.signals.macros.SignalSugar.when,
			#end
			#if tink_markup
				Fast.build,
			#end
		],
		[
			LoopSugar.transformLoop,
		]
	];
	static function apply(rules:Array<Rule>, e:Expr) {
		for (rule in rules) 
			e = rule(e);
		return e;
	}
	static public function process(ctx:ClassBuildContext) {
		for (m in ctx.members)
			switch (m.getFunction()) {
				case Success(f):
					if (f.expr != null)
						f.expr = transform(f.expr);
				default:
			}
	}
	static function transformBody(e:Expr) 
		return transform(e);
		
	static function transform(e:Expr) {
		for (rules in rules)
			e = e.transform(apply.bind(rules));
		return e;
	}
}
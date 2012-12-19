package tink.lang.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import tink.lang.macros.loops.LoopSugar;
import tink.macro.build.MemberTransformer;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

typedef Rule = Expr->Expr;

class Syntax {
	static var rules = [LoopSugar.transformLoop];
	static function apply(e:Expr) {
		var old = e;
		for (rule in rules) 
			e = rule(e);
		return
			if (old == e) old;
			else transform(e);
	}
	static public function process(ctx:ClassBuildContext) {
		for (m in ctx.members)
			switch (m.getFunction()) {
				case Success(f):
					var e = f.expr;
					if (f.expr != null)
						f.expr = (macro null).finalize(e.pos).outerTransform(function (_) return transformBody(e));
				default:
			}
	}
	static function transformBody(e:Expr) 
		return transform(e)
		
	static function transform(e:Expr) 
		return e.map(function (e:Expr, locals) return callback(apply, e).inContext(locals), null)
}
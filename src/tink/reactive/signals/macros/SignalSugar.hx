package tink.reactive.signals.macros;

import haxe.macro.Expr;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

class SignalSugar {
	static var WHEN_NAMED = macro @when(EXPR__target, NAME__data) EXPR__handle;
	static var WHEN = macro @when(EXPR__target) EXPR__handle;
	static var WITH = macro @with(EXPR__target) EXPR__statements;
	static var ON = macro @on(EXPR__signal) EXPR__handle;
	
	static function getFuture(target:Expr, handle:Expr, ?name, ?pos) {
		if (name == null) 
			name = 'result';
		return target.call(
			[handle.func([name.toArg()], false).asExpr(null, pos)],
			pos
		);
	}
	
	static public function transform(e:Expr) {
		switch (e.match(ON)) {
			case Success(match):
				var signal = match.exprs.signal;
				var t = signal.pos.makeBlankType();
				var ret =  
					if (signal.is(macro : tink.reactive.signals.Signal<$t>)) {
						var name = 'data';
						switch (signal.typeof().sure()) {
							case TType(ref, params):
								if (ref.toString() == 'tink.reactive.signals.Named')
									name = params[0].getID().substr(1);
							default:
						}
						var func = match.exprs.handle.func([name.toArg()], false).asExpr();
						(macro $signal.on($func));
					}
					else macro ${match.exprs.signal}.on(function () ${match.exprs.handle});
				return ret.finalize(e.pos);
			default:
		}
		for (pattern in [WHEN, WHEN_NAMED])
			switch (e.match(pattern)) {
				case Success(match):
					return getFuture(match.exprs.target, match.exprs.handle, match.names.data, e.pos);
				default:
			}
		switch (e.match(WITH)) {
			case Success(match):
				var target = match.exprs.target,
					statements = 
						switch (match.exprs.statements) {
							case { expr: EBlock(exprs) }: exprs;
							case e: [e]; 
						}
				for (s in statements) 						
					switch (s.match(ON)) {
						case Success(match):
							
							var signal = match.exprs.signal;
							switch (signal.expr) {
								case EConst(CIdent(name)): 
									signal.expr = 'tmp'.resolve().field(name).expr;
								case ECall({ expr: EConst(CIdent(name)) }, params):
									signal.expr = 'tmp'.resolve().field(name).call(params).expr;
								default:
							}
						default:
					}
				statements.unshift('tmp'.define(target, target.pos));
				statements.push('tmp'.resolve(target.pos));
				return statements.toBlock().finalize(e.pos);
			default:
		}
		switch (e.expr) {
			case EMeta( { name: 'when', params: [] }, { expr: ESwitch(over, cases, edef) } ):
				var arg = String.tempName();
				return getFuture(
					over, 
					ESwitch(arg.resolve(over.pos), cases, edef).at(e.pos), 
					arg, 
					e.pos
				);
			default:
		}
		return e;
	}
}
package tink.reactive.signals.macros;

import haxe.macro.Expr;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

class SignalSugar {
	static var WITH = macro @with(EXPR__target) EXPR__statements;
	static var ON = macro @on(EXPR__signal) EXPR__handle;
	
	static function getFuture(target:Expr, handle:Expr, ?name, ?pos) {
		if (name == null) 
			name = 'result';
		/*var t = (macro {
			var tmp = null;
			$target(function (d) tmp = d);
			tmp;
		}).finalize().typeof().sure().toComplex();*/
		return target.call(
			[handle.func([name.toArg()], false).asExpr(null, pos)],
			pos
		);
	}
	static function registerHandler(handle:Expr, signal:Expr) {
		signal = signal.withPrivateAccess();
		var t = signal.pos.makeBlankType();
		var ret =  
			if (signal.is(macro : tink.reactive.signals.Signal<$t>)) {
				var name = 'data';
				var t = (macro {
					var tmp = null;
					${signal}.on(function (d) tmp = d);
					tmp;
				}).finalize().typeof().sure().toComplex();
				switch (signal.typeof().sure()) {
					case TType(ref, params):
						if (ref.toString() == 'tink.reactive.signals.Named')
							name = params[0].getID().substr(1);
					default:
				}
				var func = handle.func([name.toArg(t)], false).asExpr();
				(macro $signal.on($func));
			}
			else macro $signal.on(function () $handle);
		return ret;// .finalize();
	}
	static public function on(e:Expr) 
		return
			switch (e.match(ON)) {
				case Success(match):
					match.exprs.signal.outerTransform(registerHandler.bind(match.exprs.handle));
				default: e;
			}	
			
	static public function with(e:Expr) 
		return
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
					return statements.toBlock();// .finalize(e.pos);
				default: e;
			}			
	
}
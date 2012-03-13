package tink.lang;

/**
 * ...
 * @author back2dos
 */
#if macro
	import haxe.macro.Expr;
	import tink.macro.tools.AST;
	using tink.macro.tools.MacroTools;
	using tink.core.types.Outcome;
	private typedef Qry = {
		target:Expr,
		qry:Array<QryPart>
	}
	private enum QryPart {
		Map(e:Expr);
		Filter(e:Expr);
	}
#end
class Tinq {
	@:macro static public function map<A>(e:ExprRequire<Iterable<A>>, f:Expr) {
		return TinQry.make({ target: e, qry: [Map(f)] });
	}
	@:macro static public function filter<A>(e:ExprRequire<Iterable<A>>, f:Expr) {
		return TinQry.make({ target: e, qry: [Filter(f)] });
	}
	@:macro static public function loop(ethis:Expr, bodyOrInit:Expr, ?body:Expr) {
		return TinQry.makeLoop( { target: ethis, qry:[] }, bodyOrInit, body);
	}
}
class TinQry {
	#if macro
		static public function make(q:Qry, ?pos) {
			return 'tink.lang.Tinq'.asComplexType('TinQry').partial(q, pos);
		}
		static function makeFunctor(of:Expr) {
			var n = named(of, 'x');
			return
				n.expr.func([n.name.toArg()]).toExpr(of.pos);
		}
		static public function named(e:Expr, defaultName:String) {
			switch (OpAssign.get(e)) {
				case Success(op): 
					switch (op.e1.getIdent()) {
						case Success(s): 
							//if (s.charAt(0))
							return { expr: op.e2, name: s }
						default:
					}
				default: 
			}			
			return { expr: e, name:defaultName };
		}
		static function functor(e:Expr) {
			return
				switch (e.typeof()) {
					case Success(t):
						switch (t) {
							case TFun(_): e;
							default: makeFunctor(e);
						}
					default: makeFunctor(e);
				}
		}
		static function getVName(f:Expr):String {
			return
				switch (f.typeof().sure()) {
					case TFun(args, _):
						var name = args[0].name;
						if (name.resolve().typeof().isSuccess())
							String.tempName();
						else
							name;
					default: String.tempName();
				}
		}
		static public function makeLoop(qry:Qry, bodyOrInit:Expr, body:Expr) {
			return 
				if (body.getIdent().equals('null')) unwind(qry, bodyOrInit);
				else {
					var name = 
						switch (OpAssign.get(bodyOrInit)) {
							case Success(op):
								bodyOrInit = op.e2;
								op.e1.getIdent().sure();
							default: 'ret';
						}
					[
						name.define(bodyOrInit),
						callback(unwind, qry, body).bounce(),
						name.resolve()
					].toBlock();
				}
		}
		static public function unwind(qry:Qry, body:Expr) {
			var ret = body,
				transforms = qry.qry.copy();
				
			transforms.reverse();
			body = functor(body);
			
			for (t in transforms) {
				var arg = getVName(body);
				switch (t) {
					case Map(f):
						f = functor(f);
						body = AST.build(function (eval__arg) 
							return $body($f(eval__arg))
						);
					case Filter(f):
						f = functor(f);
						body = AST.build(function (eval__arg) 
							if ($f(eval__arg))
								$body(eval__arg)
						);
				}			
			}
			var lvar = getVName(body).resolve();
			var ret:Expr = AST.build(for ($lvar in $(qry.target)) $body($lvar));
			ret = ret.transform(inlineCalls);
			return ret.log();
		}
		static function flatten(params:Array<Expr>, func:Function, body:Expr, e:Expr) {
			if (params.length != func.args.length)
				e.reject('argument count mismatch');
			var vars = [],
				params = params.copy();
			
			var substitutes:Dynamic<Expr> = { };
			var idents = new Hash();
			
			body.transform(function (e:Expr) {
				switch (e.getIdent()) {
					case Success(s):
						idents.set(s, 1 + (idents.exists(s) ? idents.get(s) : 0));
					default:
				}
				return e;
			});
			
			for (a in func.args) {
				var e = params.shift();
				switch (e.getIdent()) {
					case Success(s):
						Reflect.setField(substitutes, a.name, e);
					default: 
						if (!(idents.get(a.name) > 1)) 
							Reflect.setField(substitutes, a.name, e);
						else 
							vars.push( { name: a.name, type:a.type, expr:e } );
				}
			}
			body = body.substitute(substitutes, body.pos);
			return if (vars.length > 0)
				[EVars(vars).at(e.pos), body].toBlock(e.pos);
			else
				body;

		}
		static function inlineCalls(e:Expr):Expr {
			var ret = 
				switch (e.expr) {
					case ECall(f, params):
						switch (f.expr) {
							case EFunction(_, func): 
								switch (func.expr.expr) {
									case EReturn(body):
										flatten(params, func, body, e);
									default:
										var hasReturn = false;
										e.transform(function (e:Expr) {
											switch (e.expr) {
												case EReturn(_): hasReturn = false;
												default:
											}
											return e;
										});
										if (hasReturn) e;
										else 
											flatten(params, func, func.expr, e);
								}
							default: e;
						}
					default: e;
				}
			return ret;
		}
	#end
	@:macro public function filter(ethis:Expr, f:Expr) {
		var q:Qry = ethis.untag().data;
		q.qry.push(Filter(f));
		return TinQry.make(q);		
	}
	@:macro public function map(ethis:Expr, f:Expr) {
		var q:Qry = ethis.untag().data;
		q.qry.push(Map(f));
		return TinQry.make(q);
	}
	@:macro public function loop(ethis:Expr, bodyOrInit:Expr, ?body:Expr) {
		return makeLoop(ethis.untag().data, bodyOrInit, body);
	}
}
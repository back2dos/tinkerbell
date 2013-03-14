package tink.lang.macros;

import haxe.macro.Expr;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
using haxe.macro.ExprTools;

class Pipelining {
	static public function shortBind(e:Expr) {
		return
			if (e == null) null;
			else if (e.expr == null) e;
			else switch (e.expr) {
				case ECall(callee, args):
					var hasWildcard = false;
					args = [for (a in args) 
								if (a.isWildcard()) {
									hasWildcard = true;
									a;
								}
								else shortBind(a)
							];
					callee = shortBind(callee);
					if (hasWildcard) 
						callee = callee.field('bind', e.pos);
					callee.call(args, e.pos);
				case ESwitch(e, cases, edef):
					ESwitch(shortBind(e), [for (c in cases) { values: c.values, guard: c.guard, expr: shortBind(c.expr) } ], shortBind(edef)).at(e.pos);
				default:
					e.map(shortBind);
			}
	}
	static function parseFields(pos:Position, fields:Array<{ field : String, expr : Expr }>) 
		return 
			if (fields.length == 0) 
				pos.error('pleace specify at least one variable');
			else
				[for (f in fields) { param : f.field, operation: f.expr } ];
	
	static function parse(e:Expr, collectors:Collectors) {
		return
			switch (e.expr) {
				case EBinop(OpArrow, { expr : EObjectDecl(fields), pos: pos }, rest):
					collectors.push(parseFields(pos, fields));
					parse(rest, collectors);	
				default: 
					if (collectors.length == 0) e;
					else {
						generate({
							collectors: collectors,
							handler: e
						});// .log();
					}
			}		
	}
	static public function transform(e:Expr) 
		return parse(e, []);//TODO: this is uggly as hell
			
	static function hasReturn(e:Expr) {
		var ret = false;
		function search(e:Expr)
			switch (e.expr) {
				case EFunction(_, _):
				case EReturn(_): ret = true;
				default: e.iter(search);
			}
		search(e);
		return ret;
	}

	static function generate(d:Data) {
		
		var dType = d.handler.pos.makeBlankType();
		var chainerName = String.tempName('__chain');
		var chainer = chainerName.resolve(d.handler.pos);
		
		var yielderName = String.tempName('__yield');
		var yielder = yielderName.resolve(d.handler.pos);
		var cancelerName = String.tempName('__cancel');
		
		var collectors = d.collectors.copy();
		
		var promoter = macro tink.core.types.Surprise.promote;
		
		var body = macro @:pos(d.handler.pos) $yielder($promoter(${d.handler}));//yielderName.resolve(d.handler.pos).call([d.handler]);
		
		while (collectors.length > 0) {
			var top = collectors.pop();
			var vars = EVars([
				for (p in top) { 
					name : p.param, 
					expr: macro $promoter(${p.operation}), 
					type: null 
				}
			]).at();
			
			top.reverse();
			
			for (p in top)
				body = chainer.call([
					p.param.resolve(p.operation.pos),
					body.func([p.param.toArg()], false).asExpr()
				]);
			body = macro { $vars; $body; }
		}
		//var ret = [
			//,
		var successType = d.handler.pos.makeBlankType();
		var returnType = macro : tink.core.types.Surprise<$successType, $dType>;
		
		var chainerDecl = 
			(macro 
				function <A>(
					?dFault:tink.core.types.Surprise < A, $dType > , handler:A->Void
				) 
					$i{cancelerName} =
						dFault.get(function (o) 
							switch (o) {
								case Success(d): handler(d);
								case Failure(f): 
									$yielder(tink.core.types.Surprise.fromOutcome(tink.core.types.Outcome.Failure(f)));
							})
			).getFunction().sure().asExpr(chainerName);
					
		var ret = (macro {
			${cancelerName.define(macro null, macro : Void->Bool)};
			$chainerDecl;
			$body;
			function () return $i{cancelerName}();
		}).func([yielderName.toArg(TFunction([returnType], macro : Void))]).asExpr();
		//].toBlock();
		
		var t = d.handler.pos.makeBlankType();
			
		//return ECheckType(ret, macro : tink.core.types.Future<$t>).at();
		return macro new tink.core.types.Future<tink.core.types.Future<tink.core.types.Outcome<$successType, $dType>>>(cast $ret).flatten();
	}
}
private typedef Collectors = Array<Array<{ param:String, operation: Expr }>>;
private typedef Data = {
	collectors:Collectors,
	handler:Expr,
}
private enum Kind {
	HandlePlain;
	YieldPlain;
	HandleSurprise(e:Catch);
	YieldSurprise;
	RecoverAndYield(e:Catch);
}
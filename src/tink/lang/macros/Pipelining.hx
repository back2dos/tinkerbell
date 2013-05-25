package tink.lang.macros;

import haxe.macro.Expr;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
using haxe.macro.ExprTools;

class Pipelining {
	static public function shortBind(e:Expr):Expr {
		//TODO: this should be elsewhere
		return
			if (e == null) null;
			else if (e.expr == null) e;
			else switch (e.expr) {
				case ECall(macro $x.bind, args):
					x = shortBind(x);
					args = args.map(shortBind);
					macro $x.bind($a{args});
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
				pos.error('please specify at least one variable');
			else
				[for (f in fields) { param : f.field, operation: f.expr } ];
	
	static function parse(e:Expr, collectors:Collectors) {
		return
			switch (e.expr) {
				case EBinop(OpArrow, { expr : EObjectDecl(fields), pos: pos }, rest):
					collectors.push(parseFields(pos, fields));
					parse(rest, collectors);	
				default: 
					{
						collectors: collectors,
						handler: e
					};
			}		
	}
	static public function transform(e:Expr) {
		var data = parse(e, []);
		return
			if (data.collectors.length == 0) e;
			else generate(data, e.pos);
	}
			
	static var FUTURE = macro tink.core.types.Future;
	static var OUTCOME = macro tink.core.types.Outcome;
	static var SURPRISE = macro tink.core.types.Surprise;	
	static var OP = macro tink.lang.helpers.CollectorOp;
	
	static function generate(d:Data, pos:Position) {
		//TODO: this chould be worse. But it could be a lot better. As in readable.
		var tmp = String.tempName();
		
		var normalized = d.handler.yield(function (e:Expr) return macro @:pos(e.pos) $OP.promote($e));
		
		d.collectors.push([{ param: tmp, operation: normalized }]);
		d.handler = tmp.resolve(d.handler.pos);
		
		var dType = d.handler.pos.makeBlankType();
		var chainerName = String.tempName('__chain');
		var chainer = chainerName.resolve(d.handler.pos);
		
		var yielderName = String.tempName('__yield');
		var yielder = yielderName.resolve(d.handler.pos);
		var dissolverName = String.tempName('__dissolve');
		
		var collectors = d.collectors.copy();
		
		var promoter = macro $OP.promote;
		
		var body = macro @:pos(d.handler.pos) $yielder($OUTCOME.Success(${d.handler}));
		
		while (collectors.length > 0) {
			var top = collectors.pop();
			var vars = EVars([
				for (p in top) { 
					name : p.param, 
					expr: p.operation.yield(function (e) return macro @:pos(e.pos) $promoter($e)), 
					type: null 
				}
			]).at();
			
			top.reverse();
			
			for (p in top)
				body = chainer.call([
					p.param.resolve(p.operation.pos),
					body.func([p.param.toArg()], false).asExpr(pos)
				], pos);
			body = macro { $vars; $body; }
		}
		
		var successType = d.handler.pos.makeBlankType();
		var returnType = macro : tink.core.types.Outcome<$successType, $dType>;
		
		var chainerDecl = 
			(macro 
				function <A>(
					?dFault:tink.lang.helpers.CollectorOp<tink.core.types.Outcome< A, $dType >> , _handler:A->Void
				) 
					$i{dissolverName} =
						dFault.get(function (o:tink.core.types.Outcome< A, $dType >) 
							switch (o) {
								case Success(d): _handler(d);
								case Failure(f): 
									$yielder($OUTCOME.Failure(f));
							})
			).getFunction().sure().asExpr(chainerName, pos);
					
		var ret = (macro {
			${dissolverName.define(macro null, macro : tink.core.types.Callback.CallbackLink)};
			$chainerDecl;
			$body;
			function () return $i{dissolverName}.dissolve();
		}).func([yielderName.toArg(TFunction([returnType], macro : Void))]).asExpr(pos);
		//if (Std.string(pos).indexOf('Haxe.hx') == -1)
		return macro @:pos(pos) $OP.demote($promoter($FUTURE.ofAsyncCall($ret))).toFuture();
		//else
		//return (macro @:pos(pos) $OP.demote($promoter($FUTURE.ofAsyncCall($ret))).toFuture()).log();
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
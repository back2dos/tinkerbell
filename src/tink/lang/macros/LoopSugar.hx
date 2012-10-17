package tink.lang.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import tink.macro.build.MemberTransformer;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

class LoopSugar {
	static public function process(ctx:ClassBuildContext) {
		for (member in ctx.members)
			switch (member.getFunction()) {
				case Success(f):
					f.expr = f.expr.transform(transformLoop);
				default:
			}
	}
	static function getVar(v:Expr):LoopVar {
		return {
			name: v.getIdent().sure(),
			pos: v.pos
		}
	}	
	static function makeHead(v:LoopVar, target:LoopTarget, fallback:Null<Expr>):LoopHead {
		return {
			v: v,
			target: target,
			fallback: fallback
		}
	}
	static var W_FALLBACK = (macro EXPR__v in EXPR__target || EXPR__fallback);
	static var INTERVAL_MATCHERS = [
		[
			(macro EXPR__v += EXPR__step in EXPR__start...EXPR__end || EXPR__fallback),
			(macro EXPR__v += EXPR__step in EXPR__start...EXPR__end),
			(macro EXPR__v in EXPR__start...EXPR__end || EXPR__fallback),
			(macro EXPR__v in EXPR__start...EXPR__end)
		],
		[
			(macro EXPR__v -= EXPR__step in EXPR__start...EXPR__end || EXPR__fallback),
			(macro EXPR__v -= EXPR__step in EXPR__start...EXPR__end)
		]
	];
	static function numeric(start, end, ?step, ?up = true) {
		if (step == null) 
			step = macro 1;
		return Numeric(start, end, step, up);
	}
	static function parseSingle(e:Expr):LoopHead {
		var up = true;
		for (matchers in INTERVAL_MATCHERS) {
			for (matcher in matchers)
				switch (e.match(matcher)) {
					case Success(res): 
						return makeHead(
							getVar(res.exprs.v), 
							numeric(res.exprs.start, res.exprs.end, res.exprs.step, up), 
							res.exprs.fallback
						);
					default:
				}
			up = false;
		}
		switch (e.match(W_FALLBACK)) {
			case Success(res): 
				return makeHead(getVar(res.exprs.v), Any(res.exprs.target), res.exprs.fallback);
			default:
		}
		return
			switch (e.expr) {
				case EIn(e1, e2): 
					makeHead(getVar(e1), Any(e2), null);
				default:
					e.reject();
			}
	}
	static function parseHead(e:Expr) {
		return
			switch (e.expr) {
				case EArrayDecl(values):
					var ret = [];
					for (v in values)
						ret.push(parseSingle(v));
					ret;
				default: 
					[parseSingle(e)];
			}
	}
	static function transform(it:Expr, expr:Expr) {
		var loopFlag = temp('loop');
		
		var head = compileHeads(parseHead(it)),
			body = expr.transform(function (e:Expr) 
				return
					switch (e.expr) {
						case EBreak:
							[
								loopFlag.resolve().assign(macro false),
								macro continue,
							].toBlock();
						default: e;
					}
			);
			
		return head.init.concat([
			loopFlag.define(macro true),
			EWhile(
				OpBoolAnd.make(loopFlag.resolve(), head.condition),
				head.beforeBody.concat([
				EWhile(
					macro false,
					[body].concat(head.afterBody).toBlock(),
					false
				).at()]).toBlock(),
				true
			).at()
		]).toBlock().log();		
	}	
	static function temp(name:String) {
		return String.tempName('__tl_' + name);
	}	
	static function makeIterator(e:Expr) {
		function any() return [TPType(e.pos.makeBlankType())];
		return 
			if (e.is('Iterable'.asComplexType(any()))) 
				e.pos.at(macro $e.iterator());
			else if (e.is('Iterator'.asComplexType(any()))) 
				e;
			else 
				e.pos.errorExpr('neither Iterable nor Iterator');

	}
	static function makeCompiledHead(v:LoopVar, init:Array<Expr>, hasNext:Expr, next:Expr, fallback:Null<Expr>, hasMandatory:Bool):CompiledHead {
		var beforeBody = [],
			afterBody = [];
		if (fallback != null) {
			if (hasMandatory) {
				next = macro $hasNext ? $next : $fallback;
				hasNext = macro true;//actually the condition pretty much doesn't matter here
			}
			else {
				var flag = temp('cond');
				init.push(flag.define(macro true));
				beforeBody.push(flag.resolve().cond(flag.resolve().assign(hasNext)));
				hasNext = flag.resolve();
				next = flag.resolve().cond(next, fallback);							
			}
		}
		beforeBody.push(v.name.define(next));
		
		return {
			init: init,
			beforeBody: beforeBody,
			afterBody: afterBody,
			condition: hasNext
		}			
	}
	static function isConstNum(e:Expr) {
		return
			switch (e.expr) {
				case EConst(c):
					switch (c) {
						case CFloat(_), CInt(_): true;
						default: false;
					}
				default: false;
			}
	}
	static function getIterParts(e:Expr) {
		
	}	
	static var INT = 'Int'.asComplexType();
	static function compileHead(head:LoopHead, hasMandatory:Bool):CompiledHead {
		return
			switch (head.target) {
				case Any(e):
					//var parts = getIterParts(e);
					var target = temp('target');
					var targetExpr = target.resolve(e.pos);
					
					makeCompiledHead(
						head.v, 
						[target.define(makeIterator(e), e.pos)], 
						macro $targetExpr.hasNext(), 
						macro $targetExpr.next(), 
						head.fallback, 
						hasMandatory
					);
					
				case Numeric(start, end, step, up):
					var intLoop = step.is(INT);
						
					if (intLoop)
						for (e in [start, end])
							if (!e.is(INT))
								e.reject('should be Int');
								
					var counterName = temp('counter');						
					var counter = counterName.resolve(),
						init = [];
						
					function mk(e:Expr, name:String) 
						return
							if (isConstNum(e)) e;
							else {
								name = temp(name);
								init.push(name.define(e, e.pos));
								name.resolve(e.pos);
							}
					
					step = mk(step, 'step');
					
					if (intLoop) {
						
						var counterInit = 
							if (up) {
								end = mk(macro $end - $step, 'end');
								macro $start - $step;
							}
							else {
								end = mk(end, 'end');
								if (step.getInt().equals(1)) start;
								else macro Math.ceil(($start - $end) / $step) * $step + $end;//this should be expressed with % for faster evaluation
							}
						init.push(counterName.define(counterInit));
						
						makeCompiledHead(
							head.v,
							init,
							(up ? OpLt : OpGt).make(counter, end),
							if (up)
								macro $counter += $step
							else
								macro $counter -= $step,
							head.fallback,
							hasMandatory
						);			
					}
					else {
						var counterEndName = temp('counterEnd');
						var counterEnd = counterEndName.resolve();
						
						if (up) {
							start = mk(start, 'start');
							
							init.push(counterName.define(macro 0));
							init.push(counterEndName.define(macro Math.ceil(($end - $start) / $step)));
							
							makeCompiledHead(
								head.v,
								init,
								OpLt.make(counter, counterEnd),
								macro $counter++ * $step + $start,
								head.fallback, 
								hasMandatory
							);
						}
						else {
							end = mk(end, 'end');
							
							init.push(counterName.define(macro Math.ceil(($start - $end) / $step) - 1));
							makeCompiledHead(
								head.v,
								init,
								OpGte.make(counter, macro 0),
								macro $counter-- * $step + $end,
								head.fallback, 
								hasMandatory
							);							
						}
					}
			}
	}
	static function join(conditions:Array<Expr>, op:Binop) {
		var ret = conditions.shift();
		for (c in conditions)
			ret = op.make(ret, c);
		return ret;		
	}
	static function compileHeads(heads:Array<LoopHead>):CompiledHead {
		var hasMandatory = false;
		for (head in heads)
			if (head.fallback == null) {
				hasMandatory = true;
				break;
			}
			
		var condition = hasMandatory.toExpr(),
			init = [],
			beforeBody = [],
			afterBody = [];
			
		for (head in heads) {
			var c = compileHead(head, hasMandatory);
			
			init = init.concat(c.init);
			beforeBody = beforeBody.concat(c.beforeBody);
			afterBody = afterBody.concat(c.afterBody);
			
			if (hasMandatory) {
				if (head.fallback == null) 
					condition = OpBoolAnd.make(condition, c.condition);
			}
			else {
				condition = OpBoolOr.make(condition, c.condition);
			}
		}
		if (!hasMandatory) {
			beforeBody.push(macro if (!$condition) break);
			condition = macro true;
		}
		return {
			init: init,
			beforeBody: beforeBody,
			afterBody: afterBody,
			condition: condition
		}
	}
	static function transformLoop(e:Expr) {
		return
			switch (e.expr) {
				case EFor(it, expr):
					callback(transform, it, expr).bounce(e.pos);
				default: return e;
			}
	}
	
}
typedef CompiledHead = {
	init: Array<Expr>,
	beforeBody: Array<Expr>,
	afterBody: Array<Expr>,//this might as well be an array for simplicity
	condition: Expr
}
typedef Loop = {
	head: LoopHead,
	body: Expr
}
typedef LoopVar = { 
	name: String, 
	pos:Position,
	?t:ComplexType
};
enum LoopTarget {
	Any(e:Expr);
	Numeric(start:Expr, end:Expr, step:Expr, up:Bool);
}
typedef LoopHead = {
	v:LoopVar,
	target:LoopTarget,
	fallback:Null<Expr>,
}
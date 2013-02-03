package tink.tween.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import tink.macro.tools.TypeTools;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
using StringTools;

class TweenBuilder {
	static var ITERABLE = 'Iterable'.asComplexType([TPType('Dynamic'.asComplexType())]);
	static function handler(body:Expr, targetType:Type, additional) {
		switch (body.typeof()) {
			case Success(t):
				switch (t) {
					case TFun(_): return body;
					default:
				}
			default:
		}
		var targetType = targetType.toComplex();
		return
			body.func(
				['tween'.toArg(macro : tink.tween.Tween<$targetType>)].concat(additional)
				, false
			).asExpr(body.pos);
	}
	static function atomStatic(name:String, op) {
		var prop = (macro tmpTarget).field(name);
		return
			(macro
				function (tmpTarget) {
					if (false) $prop = .0;
					//the above is needed to make the type inferrer understand, that the field provides write access (otherwise inference will cause an error within the scope of this function), but the optimizer will throw this out for us
					var tmpStart:Float = $prop;
					var tmpDelta = ${op.e2} - tmpStart;
					return
						function (amplitude:Float) {
							if (amplitude < 1e30)
								$prop = tmpStart + tmpDelta * amplitude;
							else
								tmpTarget = null;
							return null;
						}
				}
			).finalize(op.pos);
	}
	static function atomDynamic(name:String, op) {
		return
			(macro
				function (tmpTarget) {
					var tmpStart:Float = tink.reflect.Property.get(tmpTarget, $v{name});
					var tmpDelta = ${op.e2} - tmpStart;
					return
						function (amplitude:Float) {
							if (amplitude < 1e30)
								tink.reflect.Property.set(tmpTarget, $v{name}, tmpStart + tmpDelta * amplitude);
							else
								tmpTarget = null;
							return null;
						}
				}
			).finalize(op.pos);
	}
	static public function buildTween(target:Expr, group:Expr, params:Array<Expr>) {
		var targetType = target.typeof().sure();
		var isDynamic = 
			switch (targetType) {
				case TDynamic(_): 
					#if debug 
						Context.warning('Type appears to be Dynamic. No type checking can be performed, no plugins will work. This warning is only issued with -debug', target.pos);
					#end
					true;
				default: false;
			}
		
		var targetCT = targetType.toComplex(),
			tmp = String.tempName();
			
		var ret = [tmp.define(macro new tink.tween.Tween.TweenParams<$targetCT>())];//just to be sure
		
		while (params.length > 0) {
			var e = params.pop();
			var op = e.getBinop().sure();
			
			ret.push(
				switch (op.op) {
					case OpAssign:
						var name = 
							switch (op.e1.expr) {
								case EArrayDecl(exprs):
									var name = exprs.pop().getIdent().sure();
									for (e in exprs)
										params.push(e.assign(op.e2, op.pos));
									name;
								default: 
									op.e1.getIdent().sure();
							}
						if (name.charAt(0) == '$') {
							var e = 
								if (name.substr(0, 3) == "$on") 
									handler(op.e2, targetType, []);
								else op.e2;
							tmp.resolve(op.pos).field(name.substr(1), op.e1.pos).assign(e, op.pos);
						}
						else {
							var atom = 
								switch (target.field(name).typeof()) {
									case Success(_):
										if (isDynamic) 
											atomDynamic(name, op);
										else 
											atomStatic(name, op);
									case Failure(f):
										var tp = PluginMap.getPluginFor(target, name);
										if (tp == null) 
											f.throwSelf();
										else {
											var tmp = String.tempName();
											var inst = ENew(tp, [tmp.resolve(), op.e2]).at(op.e1.pos).field('update', op.pos);
											inst.func([tmp.toArg()], 'Dynamic'.asComplexType()).asExpr(op.pos);
										}
								}
							(macro $i{tmp}.addAtom($v{name}, $atom)).finalize(op.pos);
						}
					case OpLt, OpLte:
						var e = handler(op.e2, targetType, ['forward'.toArg('Bool'.asComplexType())]);
						(
							if (op.e1.getIterType().isSuccess())
								macro for (tmp in ${op.e1}) $i{tmp}.addCuePoint(tmp, $e)								
							else 
								macro $i{tmp}.addCuepoint(${op.e1}, $e)
						).finalize(op.pos);
					default:
						op.pos.error('cannot handle ' + op.op);
				}
			);
		}
		ret.push(macro $i{tmp}.start($group, $target));
		return ret.toBlock();
	}
}
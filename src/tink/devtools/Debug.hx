package tink.devtools;

#if macro
	import haxe.macro.Expr;
	using tink.macro.tools.MacroTools;
#end

/**
 * ...
 * @author back2dos
 */

class Debug {
	@:macro static public function assert(exprs:Array<ExprRequire<Bool>>) {
		var nop = [].toBlock();
		#if debug
			function fail(e:Expr) {
				var msg = 'Unsatisfied condition ' + e.toString();
				return EThrow(msg.toExpr()).at(e.pos);
			}
			var ret = [];
			for (e in exprs) 
				ret.push(e.cond(nop, fail(e), e.pos));
			return ret.toBlock();
		#else
			return nop;
		#end
	}
	#if macro
		static function logExprs(exprs:Array<Expr>) {
			var args = [];
			var tmpName = String.tempName();
			var tmp = tmpName.resolve();
			for (e in exprs) 
				args.push((e.toString() + ': ').toExpr().add('Std.string'.resolve().call([args.length == 0 ? tmp : e])));
			return [
				tmpName.define(exprs[0]),
				'trace'.resolve().call([args.toArray().field('join').call([', '.toExpr()])]),
				tmp
			].toBlock();		
		}
	#end
	@:macro static public function log(exprs:Array<Expr>) {
		return 
			#if debug
				logExprs(exprs);
			#else
				exprs[0];
			#end
	}
}
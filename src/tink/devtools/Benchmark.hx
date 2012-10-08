package tink.devtools;

/**
 * ...
 * @author back2dos
 */

import haxe.Log;
import haxe.PosInfos;

#if macro
	import haxe.macro.Expr;
	import tink.macro.tools.AST;
	
	using tink.macro.tools.ExprTools;
	using tink.core.types.Outcome;
#end
class Benchmark {
	var msg:String;
	var last:Float;
	public function new(?msg) {
		this.next(msg);
	}
	inline function stamp() {
		return
			#if neko
				neko.Sys.cpuTime();
			#else
				haxe.Timer.stamp();
			#end
	}
	public function next(?msg:String, ?pos:PosInfos) {
		var now = stamp();
		if (this.msg != null) {
			Log.trace(this.msg + ' took ' + (now - last), pos);
		}
		this.last = now;
		this.msg = msg;
	}
	public function finish<T>(?value:T, ?pos:PosInfos) {
		next(pos);
		return value;
	}
	@:macro static public function measure(msg:String, e:Expr, ?times:Expr):Expr {
		if (times.getIdent().equals('null')) times = 1.toExpr();
		var msg = msg.toExpr();
		return macro {
			var __tink__b = new Benchmark($msg),
				__tink__times = $times;
			for (__tink__i in 0...__tink__times - 1) $e;
			__tink__b.finish($e);
		};		
	}	
}
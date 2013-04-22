package tink.devtools;

import haxe.Log;
import haxe.PosInfos;

#if macro
	import haxe.macro.Expr;
	
	using tink.macro.tools.ExprTools;
	using tink.core.types.Outcome;
#end
class Benchmark {
	var msg:String;
	var last:Float;
	var log:String->Float->PosInfos->Void;
	public function new(?msg, ?log) {
		this.next(msg);
		this.log = log == null ? defaultLog : log;
	}
	function defaultLog(msg:String, duration:Float, pos:PosInfos) {
		Log.trace(this.msg + ' took ' + duration, pos);
	}
	function stamp() {
		return
			haxe.Timer.stamp();
	}
	public function next(?msg:String, ?pos:PosInfos) {
		var now = stamp();
		if (this.msg != null) 
			log(this.msg, now - last, pos);
		this.last = now;
		this.msg = msg;
	}
	public function finish<T>(?value:T, ?pos:PosInfos) {
		next(pos);
		return value;
	}
	macro static public function measure(msg:ExprOf<String>, e:Expr, ?times:Expr):Expr {
		if (times.getIdent().equals('null')) times = 1.toExpr();
		return macro {
			var __tink__b = new tink.devtools.Benchmark($msg),
				__tink__times = $times;
			for (__tink__i in 0...__tink__times - 1) $e;
			__tink__b.finish($e);
		};		
	}	
}
package tink.util;

/**
 * ...
 * @author back2dos
 */
#if macro
	import haxe.macro.Expr;
	import tink.macro.tools.AST;
	import tink.macro.tools.ExprTools;
	using tink.macro.tools.ExprTools;
	using tink.util.Outcome;
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
	public function next(?msg:String) {
		var now = stamp();
		if (this.msg != null) {
			trace(this.msg + ' took ' + (now - last));
		}
		this.last = now;
		this.msg = msg;
	}
	public function finish<T>(?value:T) {
		next();
		return value;
	}
	@:macro static public function measure(msg:String, e:Expr, ?times:Expr):Expr {
		if (times.getIdent().equals('null')) times = 1.toExpr();
		return AST.build({
			var tmpB = new Benchmark($(msg.toExpr()));
			for (tmp in 0...$times - 1) $e;
			tmpB.finish($e);
		});		
	}

}

package tink.macro.tools;

/**
 * ...
 * @author back2dos
 */
#if neko
	import haxe.macro.Context;
	import haxe.macro.Expr;
	using tink.macro.tools.ExprTools;
#end
class Bouncer {
	#if neko
		static var idCounter = 0;
		static var bounceMap = new IntHash<Void->Expr>();
		static public function bounce(f:Void->Expr, ?pos) {
			var id = idCounter++;
			bounceMap.set(id, f);
			return 'tink.macro.tools.Bouncer.catchBounce'.resolve(pos).call([id.toExpr(pos)], pos);
		}
		static function doBounce(id:Int) {
			return
				if (bounceMap.exists(id)) 
					bounceMap.get(id)();
				else
					Context.currentPos().error('unknown id ' + id);	
		}
		static public function unbounce(e:Expr) {
			return
				switch (e.expr) {
					case ECall(target, params):
						if (target.toString() == 'tink.macro.tools.Bouncer.catchBounce')
							switch (params[0].expr) {
								case EConst(c): 
									switch (c) {
										case CInt(s): doBounce(Std.parseInt(s));
										default: params[0].reject();
									}
								default: params[0].reject();
							}
						else e;
					default: e;	
				}
		}
	#end
	@:macro static public function catchBounce(id:Int) {
		return doBounce(id);
	}	
}
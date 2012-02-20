package tink.tween;

/**
 * ...
 * @author back2dos
 */

#if macro
	using tink.macro.tools.MacroTools;
#end

class Tweener {
	@:macro static public function tween(exprs:Array<haxe.macro.Expr>) {
		return
			if (exprs.length == 0) 
				haxe.macro.Context.currentPos().error('at least one argument required');
			else 
				tink.tween.macros.TweenBuilder.buildTween(exprs.shift(), exprs);
	}
}
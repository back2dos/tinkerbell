package tink.tween;

#if macro
	using tink.macro.tools.MacroTools;
#end

class Tweener {
	#if !macro
		static public var group(get_group, null):TweenGroup;
		static function init() {
			var ret = new TweenGroup();
			group = ret;
			#if (flash || nme || js)
				TweenTicker.framewise(ret);
			//#elseif js
				//TweenTicker.periodic(ret);
			#end
			return ret;
		}
		static inline function get_group() {
			return 
				if (group == null) init();
				else group;
		}
	#end
	macro static public function tween(exprs:Array<haxe.macro.Expr>) {
		return
			if (exprs.length == 0) 
				haxe.macro.Context.currentPos().error('at least one argument required');
			else 
				tink.tween.macros.TweenBuilder.buildTween(exprs.shift(), 'tink.tween.Tweener.group'.resolve(), exprs);
	}
	
}
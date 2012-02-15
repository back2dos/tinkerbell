package tink.native;
#if macro
	import tink.macro.tools.AST;
	import haxe.macro.Expr;
#end
/**
 * ...
 * @author back2dos
 */

class PHP {
	@:macro static public function embed(s:String) {
		return AST.build(untyped __php__('eval__s'));
	}
}
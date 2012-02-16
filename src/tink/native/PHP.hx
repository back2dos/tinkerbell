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
	static public function objHash(key:Dynamic):String {
		if (embed('is_array($key)')) {
			if (embed('is_callable($key)')) 
				return objHash(key[0]) + key[1];
			else 
				throw 'cannot handle native PHP arrays yet';
		}
		else return embed('spl_object_hash($key)');
	}
}
package tink.native;
#if macro
	import haxe.macro.Expr;
	using tink.macro.tools.MacroTools;
#end

class PHP {
	macro static public function embed(s:String) {
		var s = s.toExpr();
		return macro untyped __php__($s);
	}
	static public function objMap(key:Dynamic):String {
		if (embed('is_array($key)')) {
			if (embed('is_callable($key)')) 
				return objMap(key[0]) + key[1];
			else 
				throw 'cannot handle native PHP arrays yet';
		}
		else return embed('spl_object_hash($key)');
	}
}
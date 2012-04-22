package tink.ui.controls;

/**
 * ...
 * @author back2dos
 */
import haxe.macro.Expr;

@:macro class Default {
	static public function or(value, fallback) {
		return tink.macro.tools.AST.build( {
			var tmp = $value;
			if (tmp == null) 
				$fallback;
			else 
				tmp;
		});
	}
}
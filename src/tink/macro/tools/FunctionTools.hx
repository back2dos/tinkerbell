package tink.macro.tools;

/**
 * ...
 * @author back2dos
 */
import haxe.macro.Expr;
using tink.macro.tools.ExprTools;
class FunctionTools {
	static public function toExpr(f:Function, ?name, ?pos) {
		return EParenthesis(EFunction(name, f).at(pos)).at(pos);
	}
}

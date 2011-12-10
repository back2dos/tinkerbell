package tink.macro.tools;

/**
 * ...
 * @author back2dos
 */
#if (macro || neko)
typedef Exprs = ExprTools;
typedef Types = TypeTools;
#end
class MacroTools {
	static var idCounter = 0;	
	static public inline function tempName():String {
		return '__tinkTmp' + Std.string(idCounter++);
	}
}
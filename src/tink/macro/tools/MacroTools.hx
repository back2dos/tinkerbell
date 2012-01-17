package tink.macro.tools;

/**
 * ...
 * @author back2dos
 */
#if (macro || neko)
typedef Funcs = FunctionTools;
typedef Exprs = ExprTools;
typedef Types = TypeTools;
typedef Binops = OpTools.BinopTools;
typedef Unops = OpTools.UnopTools;
#end
class MacroTools {
	static var idCounter = 0;	
	static public inline function tempName(c:Class<String>, ?prefix = '__tinkTmp'):String {
		return prefix + Std.string(idCounter++);
	}
}
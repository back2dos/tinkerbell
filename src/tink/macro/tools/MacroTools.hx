package tink.macro.tools;

/**
 * ...
 * @author back2dos
 */
#if (macro || neko)
typedef Poses = PosTools;
typedef Funcs = FunctionTools;
typedef Exprs = ExprTools;
typedef Metas = MetadataTools;
typedef Bounce = Bouncer;
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
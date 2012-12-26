package tink.macro.tools;

#if macro
	typedef Poses = PosTools;
	typedef Exprs = ExprTools;
	typedef Funcs = FunctionTools;
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
package tink.macro.tools;

#if macro
	import haxe.macro.Context;
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
	static public function deprecate<A>(at:haxe.PosInfos, useInstead:String, ret:A, ?p:haxe.PosInfos) {
		try {
			var lines = sys.io.File.getContent(at.fileName).split('\n'),
				min = 0,
				line = lines[at.lineNumber - 1];
			
			for (i in 0...at.lineNumber-1)
				min += lines[i].length + 1;
			
			var max = min + line.length;
			
			function count(haystack:String, needle)
				return haystack.split(needle).length - 1;
			
			if (count(line, p.methodName) == 1) {
				min += line.indexOf(p.methodName);
				max = min + p.methodName.length;
			}
			Context.warning(p.className + '::' + p.methodName + ' is deprecated. Use $useInstead instead', Context.makePosition( {
				min: min,
				max: max,
				file: at.fileName
			}));
		}
		catch (e:Dynamic) 
			haxe.Log.trace('This function is deprecated, use $useInstead instead. Call site: ${p.className}@${p.lineNumber}');
		
		return ret;
	}
}
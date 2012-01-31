package tink.util;

#if neko
	import haxe.io.Bytes;
	import haxe.macro.Context;
	import neko.FileSystem;
	import neko.io.File;

	using tink.macro.tools.MacroTools;
#end
/**
 * ...
 * @author back2dos
 */

class Embed {
	@:macro static public function stringFromFile(file:String) {
		//TODO: consider adding support for line numbers
		var name = String.tempName();
		var caller = Context.getPosInfos(Context.currentPos()).file.split('/');
		caller.pop();
		caller.push(file);
		file = caller.join('/');
		return 
			if (FileSystem.exists(file))
				File.getContent(file).toExpr();
			else
				Context.currentPos().error('cannot find file ' + file);
	}
}
package tink.util;

#if macro
	import haxe.io.Bytes;
	import haxe.macro.Context;
	import sys.FileSystem;
	import sys.io.File;

	using tink.macro.tools.MacroTools;
#end

class Embed {
	macro static public function filePath(file:String) {
		var caller = Context.getPosInfos(Context.currentPos()).file.split('/');
		caller.pop();
		caller.push(file);
		file = caller.join('/');
		return FileSystem.fullPath(file).toExpr();
	}
	macro static public function stringFromFile(file:String) {
		//TODO: consider adding support for line numbers
		var name = String.tempName();
		var caller = Context.getPosInfos(Context.currentPos()).file.split('/');
		caller.pop();
		caller.push(file);
		file = caller.join('/');
		return 
			if (FileSystem.exists(file)) {
				Context.registerModuleDependency(Context.getLocalClass().get().module, file);
				File.getContent(file).toExpr();
			}
			else
				Context.currentPos().error('cannot find file ' + file);
	}
}
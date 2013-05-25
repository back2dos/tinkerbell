package tinx.node.io;

import tink.lang.Cls;
import tinx.node.Runtime;
import tink.core.types.Outcome;

using tinx.node.Error;

private typedef NativeFS = {
	function createReadStream(path:String, options:Dynamic):NativeIn;
	function createWriteStream(path:String, options:Dynamic):NativeOut;
	function readdir(path:String, cb:Handler<Array<String>>):Void;
	function stat(path:String, cb:Handler<FileStats>):Void;
	function lstat(path:String, cb:Handler<FileStats>):Void;
	function rename(from:String, to:String, cb:Handler<Class<Void>>):Void;
	function unlink(file:String, cb:Handler<Class<Void>>):Void;
}
typedef FileStats = {
	function isFile():Bool;
	function isDirectory():Bool;
	function isBlockDevice():Bool;
	function isCharacterDevice():Bool;
	function isSymbolicLink():Bool;
	function isFIFO():Bool;
	function isSocket():Bool;
	//TODO: I really think theses should be renamed ... access, modified, created?
	var atime(default, null):Date;
	var mtime(default, null):Date;
	var ctime(default, null):Date;
}

enum FileTree {
	File(name:String, stats:FileStats);
	Dir(name:String, children:Array<FileTree>);
}
class FS implements Cls {
	static var native:NativeFS = Runtime.load('fs');
	
	static public function rename(from:String, to:String) 
		return {
			ret: native.rename(from, to, _)
		} => true;
		
	static public function unlink(file) 
		return {
			ret: native.unlink(file, _)
		} => true;
	
	static public function read(path) 
		return new InStream(native.createReadStream(path, { } ));
		
	static public function write(path)
		return new OutStream(native.createWriteStream(path, { } ));
		
	static public function ls(path):Unsafe<Array<String>>
		return { content : native.readdir(path, _) } => content;
		
	static public function stat(path, ?follow = true):Unsafe<FileStats>
		return { stat: (follow ? native.stat : native.lstat)(path, _) } => stat;
	
	static public function tree(path, ?depth = 255, ?follow = true):Unsafe<FileTree> 
		return { 
			stat: stat(path, follow)
		} => {
			if (stat.isDirectory()) 
				if (depth > 0) 
					{ 
						content : ls(path) 
					} => {
						subtrees : [for (name in content) tree('$path/$name', depth - 1, follow)]
					} => {
						Dir(path, subtrees);
					}
				else
					Dir(path, []);
			else 
				File(path, stat);
		}	

	static public function crawl(path, ?depth = 255, ?follow = true) 
		return new FSCrawler(path, depth, follow);
	
}

class FSCrawler implements Cls {
	@:signal var data: { path : String, stat: FileStats };
	@:signal var error: Error;
	@:future var end;
	@:read var readable = true;//TODO: consider making this bindable
	var pending = 0;
	public function new(path, depth, follow) 
		crawl(path, depth, follow); 
		
	function crawl(path, depth, follow) 
		if (depth > 0 && readable) {
			pending++;
			//TODO: this looks horrible. Pipelines should allow for a more elegant solution. For starters an @until(closed) should help.
			({ stat : FS.stat(path, follow) }
			=> { 
				if (readable) { 
					_data.invoke( { path: path, stat: stat });
					if (stat.isDirectory()) 
						{
							files: FS.ls(path)
						} => {
							if (readable)
								for (f in files)
									crawl('$path/$f', depth - 1, follow);
							release();
							readable;//have to return something
						}
					else release();
				}
				else release();
				stat;
			}).get(function (result) 
				switch (result) {
					case Failure(f):
						if (readable) 
							_error.invoke(f);
						release();
					default:
				}
			);
		}
	inline function release()
		if (--pending == 0) {
			_end.invoke(Noise);
			destroy();
		}

	public function destroy() 
		readable = false;
}
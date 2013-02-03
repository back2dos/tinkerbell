package tinx.node.io;

import tink.collections.maps.Map;
import tinx.node.Runtime;

using tinx.node.Exception;

private typedef NativeFS = {
	function createReadStream(path:String, options:Dynamic):NativeIn;
	function createWriteStream(path:String, options:Dynamic):NativeOut;
	function readdir(path:String, cb:Handler<Array<String>>):Void;
	function stat(path:String, cb:Handler<FileStats>):Void;
	function lstat(path:String, cb:Handler<FileStats>):Void;
}
typedef FileStats = {
	function isFile():Bool;
	function isDirectory():Bool;
	function isBlockDevice():Bool;
	function isCharacterDevice():Bool;
	function isSymbolicLink():Bool;
	function isFIFO():Bool;
	function isSocket():Bool;
	//TODO: I really think theses should be renamed ...
	var atime(default, null):Date;
	var mtime(default, null):Date;
	var ctime(default, null):Date;
}

enum FileTree {
	File(name:String, stats:FileStats);
	Dir(name:String, children:Array<FileTree>);
}
class FS {
	static var native:NativeFS = Runtime.load('fs');
	
	static public function read(path) 
		return new InStream(native.createReadStream(path, { } ))
		
	static public function write(path)
		return new OutStream(native.createWriteStream(path, { } ))
		
	static public function ls(path):Unsafe<Array<String>>
		return native.readdir.bind(path).future()
		
	static public function stat(path, ?follow = true):Unsafe<FileStats>
		return (follow ? native.stat : native.lstat).bind(path).future()
		
	static public function tree(path, ?depth = 255, ?follow = true):Unsafe<FileTree> 
		return //the following code is probably slow as hell
			stat(path, follow).chain(function (s:FileStats) 
				return
					if (s.isDirectory()) 
						if (depth > 0)
							ls(path).chain(
								function (paths:Array<String>) 
									return 
										[for (p in paths) 
											tree(path + '/' + p, depth - 1, follow)
										].merge().map(Dir.bind(path))
							)
						else
							function (handler) 
								handler(Success(Dir(path, [])))
					else
						function (handler) 
							handler(Success(File(path, s)))
			)	
	static public function crawl(path, ?depth = 255, ?follow = true) 
		return new FSCrawler(path, depth, follow)
	
}

class FSCrawler implements tink.lang.Cls {
	@:signal var data: { path : String, stat: FileStats };
	@:signal var error: Exception;
	@:signal var end:Void;
	@:read var readable = true;//should become bindable
	var pending = 0;
	public function new(path, depth, follow) 
		crawl(path, depth, follow) 
		
	function crawl(path, depth, follow) 
		if (depth > 0) {
			pending++;
			@when(FS.stat(path, follow)) 
				if (readable) {
					switch (result) {
						case Success(stat):
							_data.fire( { path: path, stat: stat } );
							if (stat.isDirectory()) 
								@when switch FS.ls(path) {
									case Success(files):
										for (f in files)
											crawl('$path/$f', depth - 1, follow);
										release();
									case Failure(e):
										_error.fire(e);
										release();
								}
							else release();
						case Failure(e):
							_error.fire(e);
					}
				}
		}
	inline function release()
		if (--pending == 0) {
			_end.fire();
			destroy();
		}

	public function destroy() {
		readable = false;
	}
}
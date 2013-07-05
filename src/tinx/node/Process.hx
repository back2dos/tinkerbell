package tinx.node;

import tink.core.types.Callback;
import tink.core.types.Future;
import tink.core.types.Signal;
import tinx.node.Error;
import tink.lang.Cls;
import tinx.node.events.Emitter;

import tinx.node.io.*;

private typedef NativeProcess = {>Emitter,
	function kill(?signal:String):Void;
	var pid(default, null):String;
	var stdin:NativeOut;
	var stdout:NativeIn;
	var stderr:NativeIn;
}

typedef ProcessExit = { code: Null<Int>, signal:Null<String> };

class Process implements Cls {
	//TODO: process.spawn seems more adequate ... but doesn't work
	@:forward(kill, pid) var native:NativeProcess = _;
	
	@:read var stdin:OutStream = new OutStream(native.stdin);
	@:read var stdout:InStream = new InStream(native.stdout);
	@:read var stderr:InStream = new InStream(native.stderr);
	
	public var exit(default, null):Future<ProcessExit> = Future.ofAsyncCall(
		function (handler)
			native.addListener(
				'exit', 
				function (code, signal) 
					handler( { code: code, signal: signal } )
			)
	);
	private function new() {}
	static public function spawn(cmd:String, args:Array<String>, ?cwd = './') {
		return new Process(process.spawn(cmd, args, { cwd : cwd }));
	}
	static public function exec(cmd:String, args:Array<String>, ?cwd = './') {
		return new Process(process.exec(cmd, args, { cwd : cwd }));
	}
	static public function execFile(cmd:String, args:Array<String>, ?cwd = './') {
		return new Process(process.execFile(cmd, args, { cwd : cwd }));
	}
	static var process:Dynamic = Runtime.load('child_process');
}
package tinx.node;

import tink.core.types.Callback;
import tink.core.types.Signal;

@:native('process') extern class Runtime {
	static public function nextTick(f:Void->Void):Void;
	static public var platform(default, null):String;
	static public function binding<A>(id:String):A;
	static public function cwd():String;
	static public function exit(?code:Int = 0):Dynamic;
	static public var argv(default, null):Array<String>;
	static public var execPath(default, null):String;
	
	static public var onExit(default, null):Signal<Noise>;
	static public var onError(default, null):Signal<Error>;
	
	static public inline function onSignal(type:String):Signal<Noise>
		return mkSignal(type).noise();
	
	static private inline function mkSignal<A>(type:String):Signal<A> 
		return new Signal(function (handler) {
			var f = function (e) handler.invoke(e);
			untyped process.on(type, f);
			return untyped function () process.un(type, f);
		});

	static function __init__():Void {
		onExit = mkSignal('exit').noise();
		onError = mkSignal('uncaughtException');
	}		
	
	static public inline function load<A>(s:String):A
		return untyped require(s);
		
	static public inline function log(v:Dynamic):Void 
		untyped console.log(v);
		
	static public inline function env(id:String):Dynamic	
		return untyped process.env[id];		
		
}
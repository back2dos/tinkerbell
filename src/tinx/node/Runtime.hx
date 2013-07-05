package tinx.node;

import haxe.ds.Option;
import haxe.ds.StringMap;
import tink.core.types.Callback;
import tink.core.types.Signal;

@:native('process') extern class Runtime {
	static public function nextTick(f:Void->Void):Void;
	static public var platform(default, null):String;
	static public function binding<A>(id:String):A;
	static public function cwd():String;
	static public function exit(?code:Int = 0):Dynamic;
	static public var argv(default, null):Array<String>;
	static public var argMap(get, null):StringMap<Option<String>>;
	static inline function get_argMap():StringMap<Option<String>> {
		if (Runtime.argMap == null) {
			var ret = new StringMap(),
				args = argv.copy();
			function isOption(s:String)
				return s.charAt(0) == '-';
			while (args.length > 0) 
				switch args.shift() {
					case option if (isOption(option)):
						ret.set(
							option.substr(1), 
							if (args.length == 0 || isOption(args[0])) None
							else Some(args.shift())
						);
					case _:
					//case unexpected: throw 'unexpected argument $unexpected';
				}			
			Runtime.argMap = ret;
		}
		return Runtime.argMap;
	}
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
	
	static public inline function load<A>(s:String):A//TODO: rename to require
		return untyped require(s);
		
	static public inline function log(v:Dynamic):Void 
		untyped console.log(v);
		
	static public inline function env(id:String):Dynamic	
		return untyped process.env[id];		
		
}
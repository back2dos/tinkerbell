package tinx.node;

@:native('process') extern class Runtime {
	static public function nextTick(f:Void->Void):Void;
	static public var platform(default, null):String;
	static public function binding<A>(id:String):A;
	static public function cwd():String;
	
	static public var argv(default, null):Array<String>;
	static public var execPath(default, null):String;
	
	static public inline function load<A>(s:String):A
		return untyped require(s)
	static public inline function env(id:String):String 
		return untyped process[id]
}
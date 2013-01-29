package tinx.node;

@:native('process') extern class Lib {
	static public function nextTick(f:Void->Void):Void;
	static public var platform(default, null):String;
	static public function binding<A>(id:String):A;
	static public function cwd():String;
	static public inline function module<A>(s:String):A 
		return untyped require(s)
	static public inline function env(id:String):String 
		return untyped process[id]
}
package tinx.node.io;

@:native('Buffer') extern class Buffer implements ArrayAccess<Int> {
	public function new(str:String, ?encoding:Encoding):Void;
	@:overload(function (encoding:Encoding = 'utf8'):String {})
	public function toString():String;
	static public function isBuffer(v:Dynamic):Bool;
	static public function concat(buffers:Array<Buffer>):Buffer;
}
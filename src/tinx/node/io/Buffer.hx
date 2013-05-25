package tinx.node.io;

@:native('Buffer') extern class Buffer implements ArrayAccess<Int> {
	public function new(str:String, ?encoding:Encoding):Void;
	public var length(default, null):Int;
	@:overload(function (encoding:Encoding = 'utf8'):String {})
	public function toString():String;
	public function slice(?from:Int, ?to:Int):Buffer;
	static public function isBuffer(v:Dynamic):Bool;
	static public function concat(buffers:Array<Buffer>):Buffer;
    static public function byteLength(string:String, ?encoding:Encoding):Int; 
}
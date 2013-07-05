package tinx.node;

import tink.core.types.Future;
import tink.core.types.*;

@:native('Error')
extern class Error {
	public var code(default, null):String;
	public var message(default, null):String;
	public var stack(default, null):String;
	public var data(default, null):Dynamic;
	function new(message:String):Void;
	static public inline function make(code:String, ?message:String, ?data:Dynamic):Error {
		var ret = new Error(if (message == null) code else message);
		ret.code = code;
		ret.data = data;
		return ret;
	}
}

typedef Handler<T> = LeftFailingHandler<T, Error>;
typedef Unsafe<T> = Future<Outcome<T, Error>>;
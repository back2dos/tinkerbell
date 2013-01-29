package tinx.node.io;
import tinx.node.events.Emitter;

typedef NativeOut = {>Emitter,
	var writable(default, null):Bool;
	@:overload(function (data:String, encoding:Encoding):Bool {})
	function write(data:Buffer):Bool;
	@:overload(function (data:String, encoding:Encoding):Void {})
	function end(?data:Buffer):Void;
	function destroy():Void;
	function destroySoon():Void;
}
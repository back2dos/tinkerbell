package tinx.node.io;
import tinx.node.events.Emitter;

typedef NativeIn = {>Emitter,
	var readable(default, null):Bool;
	function pause():Void;
	function resume():Void;
	function destroy():Void;
}
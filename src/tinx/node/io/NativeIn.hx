package tinx.node.io;

import tinx.node.events.Emitter;

typedef NativeIn = {>Emitter,
	var readable(default, null):Bool;
	function setEncoding(encoding:String):Void;
	function pause():Void;
	function resume():Void;
	function destroy():Void;
}
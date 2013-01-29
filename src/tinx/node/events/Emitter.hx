package tinx.node.events;

typedef Emitter = {
	function addListener(type:String, handler:Dynamic):Void;
	function removeListener(type:String, handler:Dynamic):Void;
	function once(type:String, handler:Dynamic):Void;
}
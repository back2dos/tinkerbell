package tinx.nw;
import tinx.node.events.Emitter;

///@see https://github.com/rogerwang/node-webkit/wiki/Native-UI-API-Manual
@:native('require("nw.gui")')
extern class NativeUI {
	static var Window(default, null): {
		function get():NativeWindow;
		function open(url:String, ?options: {
			@:optional var title:String;
			
			@:optional var width:Int;
			@:optional var height:Int;
			@:optional var toolbar:Bool;
			@:optional var icon:String;
			@:optional var position:String;//mouse or center
			@:optional var min_width:Int;
			@:optional var min_height:Int;
			@:optional var max_width:Int;
			@:optional var max_height:Int;
			//always-on-top - you can always set this with json notation			
			@:optional var as_desktop:Bool;
			@:optional var resizable:Bool;
			@:optional var fullscreen:Bool;
			@:optional var frame:Bool;
			@:optional var show:Bool;
			@:optional var kiosk:Bool;
		}):Void;
	};
	static var App:NativeApp;
}

@:events(
	"close",
	"closed",
	"loading",
	"loaded",
	"focus",
	"blur",
	"minimize",
	"restore",
	"maximize",
	"unmaximize",
	"enter-fullscreen",
	"leave-fullscreen",
	"zoom"
)
typedef NativeWindow = {>Emitter,
	var window(default, null):js.html.DOMWindow;
	var x:Int;
	var y:Int;
	var width:Int;
	var height:Int;
	var title:String;
	var isFullscreen:Bool;
	var isKioskMode:Bool;
	var zoom:Float;
	
	function moveTo(x:Int, y:Int):Void;
	function moveBy(x:Int, y:Int):Void;
	function resizeTo(width:Int, height:Int):Void;
	function resizeBy(width:Int, height:Int):Void;
	function focus():Void;
	function blur():Void;
	function show():Void;
	function hide():Void;
	function close(?force:Bool):Void;
	function reload():Void;
	function reloadIgnoringCache():Void;
	function maximize():Void;
	function unmaximize():Void;
	function minimize():Void;
	function restore():Void;
	function enterFullscreen():Void;
	function leaveFullscreen():Void;
	function toggleFullscreen():Void;
	function enterKioskMode():Void;
	function leaveKioskMode():Void;
	function toggleKioskMode():Void;
	function showDevTools():Void;
	function setMaximumSize(width:Int, height:Int):Void;
	function setMinimumSize(width:Int, height:Int):Void;
	function setResizable(resizable:Bool):Void;
	function setAlwaysOnTop(top:Bool):Void;
	function setPosition(position:String):Void;//can be "center"
	function requestAttention(attention:Bool):Void;
	function capturePage(callback:String->Void, ?image_format:String):Void;	
}

@:events("open")
typedef NativeApp = {>Emitter,
	var argv(default, null):Array<String>;
	function quit():Void;
	function closeAllWindows():Void;
}
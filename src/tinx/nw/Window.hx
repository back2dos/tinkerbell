package tinx.nw;

import tink.lang.Cls;

class Window implements Cls {
	@:forward(!("*Fullscreen"|"*Kioskmode"|once|"*Listener"))
	var target:NativeUI.NativeWindow = _;
	
	@:prop var fullscreen:Bool;
	
	private function new() {
		for (state in ["enter", "leave"])
			this.target.addListener(
				'$state-fullscreen', 
				this.bindings.byString.fire("fullscreen", _)
			);
	}
	
	static public var main(default, null):Window = new Window(NativeUI.Window.get()); 
	
	@:bindable('fullscreen') 
	function get_fullscreen() return target.isFullscreen;
	function set_fullscreen(param) return target.isFullscreen = param;
}
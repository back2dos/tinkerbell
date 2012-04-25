package tink.ui.controls;

import flash.display.Sprite;
import tink.ui.style.Flow;

import tink.lang.Cls;
import tink.ui.core.UIComponent;
import tink.ui.core.UIContainer;
import tink.ui.style.Style;
import tink.ui.controls.Button;
import tink.ui.style.Skin;
/**
 * ...
 * @author back2dos
 */

class ScrollBarStyle implements Style, implements Cls {
	@:forward("margin*", "*Align", width, height) var container:ContainerStyle = _;
	
	var _prev:ButtonStyle = _;
	var _next:ButtonStyle = _;
	var _thumb:ButtonStyle = _;
	var _track:ButtonStyle = _;
	
	@:read(_prev.normal) var prev:States<Skin>;
	@:read(_next.normal) var next:States<Skin>;
	@:read(_thumb.normal) var thumb:States<Skin>;
	@:read(_track.normal) var track:States<Skin>;
	
	@:bindable var horizontal = true;
	@:bindable var width = true;
	@:bindable var height = true;
	
}
 
class ScrollBar extends UIComponent<Sprite, ScrollBarStyle>, implements Cls {
	
	var prev = new Button();
	var next = new Button();
	var thumb = new Button();
	var track = new Button();
	
	var container = new UIContainer();
	var stack = new UIContainer();
	
	public function new() {
		var s = cast(container.getView(), Sprite);		
		
		super(s, new ScrollBarStyle(container.style, prev.style, next.style, thumb.style, track.style));
		
		container.addChild(prev);
		container.addChild(stack);
		container.addChild(next);
		
		prev.caption = 'prev';
		next.caption = 'next';
		stack.style.flow = Flow.Stack;
		
		stack.addChild(thumb);
		stack.addChild(track);
	}
	override function getMetrics() 
		return container.getMetrics()
}
package tink.ui.controls;

import flash.display.Sprite;
import tink.ui.core.Metrics;
import tink.ui.core.UILeaf;
import tink.ui.style.Flow;

import tink.lang.Cls;
import tink.ui.core.UIComponent;
import tink.ui.core.UIContainer;
import tink.ui.core.Pair;
import tink.ui.style.Style;
import tink.ui.controls.Button;
import tink.ui.style.Skin;

using tink.reactive.bindings.BindingTools;
/**
 * ...
 * @author back2dos
 */

class ScrollBarStyle implements Style, implements Cls {
	@:forward("margin*", "*Align") var container:ContainerStyle = _;
	
	var _prev:ButtonStyle = _;
	var _next:ButtonStyle = _;
	var _thumb:ButtonStyle = _;
	var _track:ButtonStyle = _;
	
	@:read(_prev.normal) var prev:States<Skin>;
	@:read(_next.normal) var next:States<Skin>;
	@:read(_thumb.normal) var thumb:States<Skin>;
	@:read(_track.normal) var track:States<Skin>;
	
	@:bindable var horizontal = false;	
	@:bindable var thickness = 16.0;
	@:bindable var length = Size.Rel(1);
	public function new() {
		updateThickness.bindExpr( { horizontal; thickness; length; } );
	}
	function updateThickness(_) {
		_prev.width = _prev.height = _next.width = _next.height = Const(thickness);
		if (horizontal) {
			container.width = length;
			container.height = Const(thickness);
			container.flow = Flow.Right;
		}
		else {
			container.width = Const(thickness);
			container.height = length;			
			container.flow = Flow.Down;
		}
	}
}

class ScrollBar extends UIComponent<Sprite, ScrollBarStyle>, implements Cls {
	
	var prev = new Button();
	var next = new Button();
	var thumb = new Button();
	var track = new Button();
	
	var container = new UIContainer();
	var stack = new UIContainer();
	
	@:bindable @:prop(Math.max(Math.min(1, param), 0)) var percentage = .1;
	@:bindable @:prop(Math.max(Math.min(1, param), 0)) var position = .5;	
	
	public function new() {
		var s = cast(container.getView(), Sprite);		
		
		super(s, new ScrollBarStyle(container.style, prev.style, next.style, thumb.style, track.style));
		
		container.addChild(prev);
		container.addChild(stack);
		container.addChild(next);
		
		stack.style.flow = Flow.Stack;
		
		stack.addChild(track);
		stack.addChild(thumb);
		
		style.track.up = 		Skin.Draw(Plain(0xA8A8A8, 1), Plain(0, .25));
		style.track.over = 		Skin.Draw(Plain(0xB0B0B0, 1), Plain(0, .25));
		style.track.down = 		Skin.Draw(Plain(0xB8B8B8, 1), Plain(0, .25));
		style.track.disabled = 	Skin.Draw(Plain(0xB0B0B0, 1), Empty);
		
		var thumbStyle = thumb.style;
		var self = this;
		
		thumbStyle.width.bindExpr(Rel(self.style.horizontal ? self.percentage : 1));
		thumbStyle.height.bindExpr(Rel(self.style.horizontal ? 1 : self.percentage));
		thumbStyle.hAlign.bindExpr(self.position);
		thumbStyle.vAlign.bindExpr(self.position);
	}

	override function getMetrics() 
		return container.getMetrics()
}
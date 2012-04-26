package tink.ui.controls;

import flash.geom.Rectangle;
import flash.geom.Rectangle;
import tink.lang.Cls;
import tink.ui.style.Skin;
import tink.ui.style.Flow;
import tink.ui.style.Style;

import flash.events.MouseEvent;
import tink.ui.core.UIContainer;
import tink.ui.core.UIComponent;
import tink.ui.text.Label;
import flash.display.Sprite;

using tink.ui.controls.Default;
using tink.reactive.bindings.BindingTools;


/**
 * ...
 * @author back2dos
 */

private enum State {
	Up;
	Over;
	Down;
	Disabled;
}

class States<T> implements Cls {
	@:bindable var up:T;
	@:bindable var over:T;
	@:bindable var down:T;
	@:bindable var disabled:T;
	
	var fallback:State-> T;
	
	public function new(?fallback:States<T>) {
		this.fallback =
			if (fallback == null) toSelf;
			else fallback.get;
	}
	function toSelf(state:State) {
		return
			switch (state) {
				case Up: up;
				case Over: over.or(up);
				case Down: down.or(toSelf(Over));
				case Disabled: disabled.or(up);
			}
	}
	public function get(state:State) {
		var ret =
			switch (state) {
				case Up: up; 
				case Over: over; 
				case Down: down;
				case Disabled: disabled;
			}
		return ret.or(fallback(state));
	}
}
class ButtonStyle implements Style, implements Cls {
	@:read var normal = new States<Skin>();
	@:read var selected:States<Skin> = new States(normal);
	
	@:forward var container:ContainerStyle;
	@:forward var label:LabelStyle;
	
	public function new(container, label) {
		this.container = container;
		this.label = label;
		container.paddingLeft = container.paddingRight = container.paddingTop = container.paddingBottom = 5;
		normal.up = Skin.Draw(Plain(0xE0E0E0, 1), Plain(0, .25));
		normal.over = Skin.Draw(Plain(0xE8E8E8, 1), Plain(0, .25));
		normal.down = Skin.Draw(Plain(0xF0F0F0, 1), Plain(0, .25));
		normal.disabled = Skin.Draw(Plain(0xE8E8E8, 1), Plain(0, .5));
	}
}
class FlashBehavior {
	static public function wire(s:Sprite, click, down, drag, up, setState) {
		s.addEventListener(MouseEvent.CLICK, function (e:MouseEvent) click.fire( { x:s.mouseX, y:s.mouseY } ));
		s.addEventListener(MouseEvent.ROLL_OVER, function (e:MouseEvent) if (!e.buttonDown) setState(Over));
		s.addEventListener(MouseEvent.ROLL_OUT, function (e:MouseEvent) if (!e.buttonDown) setState(Up));
		s.addEventListener(MouseEvent.MOUSE_DOWN, function (e:MouseEvent) {
			var stage = s.stage;
			var x0 = stage.mouseX, 
				y0 = stage.mouseY;
			function handleDrag(_) {
				drag.fire( { dx: stage.mouseX - x0, dy: stage.mouseY - y0 } );
				x0 = stage.mouseX;
				y0 = stage.mouseY;
			}
			down.fire( { x:s.mouseX, y:s.mouseY } );
			stage.addEventListener(MouseEvent.MOUSE_MOVE, handleDrag);
			function handleUp(e) {
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, handleDrag);
				stage.removeEventListener(MouseEvent.MOUSE_UP, handleUp);
				var inside = s.hitTestPoint(stage.mouseX, stage.mouseY);
				setState(inside ? Over : Up);
				up.fire( { x:s.mouseX, y:s.mouseY, inside: inside } );
			}
			stage.addEventListener(MouseEvent.MOUSE_UP, handleUp);
			setState(Down);
		});
		s.buttonMode = true;
		s.mouseChildren = false;
		s.tabEnabled = false;
	}
}
class Button extends UIComponent<Sprite, ButtonStyle>, implements Cls {
	var label = new Label();
	var container = new UIContainer();
	
	@:prop(updateCaption(param)) var caption:String;
	
	@:bindable var enabled = true;
	@:bindable var selected = false;
	@:bindable private var state = Up;
	
	@:signal var click:{ x:Float, y:Float };
	@:signal var down:{ x:Float, y:Float };
	@:signal var drag:{ dx:Float, dy:Float };
	@:signal var up:{ x:Float, y:Float, inside:Bool };
	
	public function new() {
		var s = cast(container.getView(), Sprite);
		super(s, new ButtonStyle(container.style, label.style));
		
		FlashBehavior.wire(s, _click, _down, _drag, _up, set_state);
		
		bindSkin();
	}
	function updateCaption(text) {
		if (text != label.text) {
			if (text == null) 
				container.removeChild(label);
			else if (label.text == null) 
				container.addChildAt(label, 0);
			label.text = text;
		}
		return text;
	}
	function bindSkin() {
		//TODO: without these locals, some "unbound variable me" problem occurs
		var style = container.style;
		var self = this;
		style.skin.bindExpr(self.calcSkin());
	}
	function calcSkin():Skin {
		var states = 
			if (selected) style.selected;
			else style.normal;
		return states.get(state);
	}
	override public function getMetrics() {
		return container.getMetrics();
	}
}
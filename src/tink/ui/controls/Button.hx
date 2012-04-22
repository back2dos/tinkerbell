package tink.ui.controls;

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

class ButtonStyle implements Style, implements Cls {
	@:bindable var normal:Skin		= Skin.Draw(Plain(0xE8E8E8, 1), Plain(0, .25));
	@:bindable var over:Skin		= Skin.Draw(Plain(0xF0F0F0, 1), Plain(0, .25));
	@:bindable var down:Skin		= Skin.Draw(Plain(0xF8F8F8, 1), Plain(0, .25));
	@:bindable var disabled:Skin	= Skin.Draw(Plain(0xF0F0F0, 1), Empty);
	
	@:bindable var selectedNormal:Skin		= Skin.Draw(Plain(0xE8E8E8, 1), Plain(0, .75));
	@:bindable var selectedOver:Skin    	= Skin.Draw(Plain(0xF0F0F0, 1), Plain(0, .75));
	@:bindable var selectedDown:Skin    	= Skin.Draw(Plain(0xF8F8F8, 1), Plain(0, .75));
	@:bindable var selectedDisabled:Skin	= Skin.Draw(Plain(0xF0F0F0, 1), Plain(0, .25));
	
	@:bindable var icon:Dynamic;
	@:bindable var selectedIcon:Dynamic;
	
	@:forward var container:ContainerStyle;
	@:forward var label:LabelStyle;
	
	public function new(container, label) {
		this.container = container;
		this.label = label;
		this.marginLeft = this.marginRight = this.marginTop = this.marginBottom = 10;
	}
}

class Portion<T> {
	@:bindable var up:Skin;
	@:bindable var over:Skin;
	@:bindable var down:Skin;
	var fallback:Null<Portion<T>>;
	public function new(?fallback) {
		this.fallback = fallback;
	}
	public function get(state:State) {
		//return
			//switch (state) {
				//case 
			//}
	}
}
private enum State {
	Over;
	Normal;
	Down;
}

class Button extends UIComponent<Sprite, ButtonStyle>, implements Cls {
	var label = new Label();
	var container = new UIContainer();
	
	@:prop(updateCaption(param)) var caption:String;
	@:bindable var enabled = true;
	@:bindable var selected = false;
	@:bindable private var state = Normal;
	
	public function new() {
		var s = cast(container.getView(), Sprite);
		super(s, new ButtonStyle(container.style, label.style));
		
		s.addEventListener(MouseEvent.ROLL_OVER, function (e) state = e.buttonDown ? Down : Over);
		s.addEventListener(MouseEvent.ROLL_OUT, function (_) state = Normal);
		s.addEventListener(MouseEvent.MOUSE_DOWN, function (_) state = Down);
		s.addEventListener(MouseEvent.MOUSE_UP, function (_) state = Over);
		
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
		//TODO: there must be a more elegant solution to all this
		function plainSkin(state) 
			return switch (state) {
				case Normal: style.normal;
				case Over: style.over.or(style.normal);
				case Down: style.down.or(plainSkin(Over));
			}
		
		return
			if (enabled) {
				if (selected) 
					switch (state) {
						case Normal: style.selectedNormal.or(plainSkin(Normal));
						case Over: style.selectedOver.or(plainSkin(Over));
						case Down: style.selectedOver.or(plainSkin(Down));
					}
				else
					plainSkin(state);
			}
			else 
				if (selected) 
					style.selectedDisabled.or(style.disabled);
				else 
					style.disabled;
	}
	override public function getMetrics() {
		return container.getMetrics();
	}
}
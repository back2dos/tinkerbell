package tink.ui.text;

import flash.filters.DropShadowFilter;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.events.MouseEvent;

import tink.lang.Cls;
import tink.ui.core.UIComponent;
import tink.ui.core.UIPaneBase;
import tink.ui.style.Style;
import tink.ui.style.Skin;

using tink.reactive.bindings.BindingTools;
using tink.ui.style.Skin;
/**
 * ...
 * @author back2dos
 */
class DisabledInputStyle implements Cls {
	@:bindable var skin = Draw(
		Linear([0xDDDDDD, 0xCCCCCC], [1, 1], [0x00, 0xFF], -Math.PI / 4 * 3), 
		Linear([0xAAAAAA, 0x999999], [1, 1], [0x00, 0xFF], -Math.PI / 4 * 7),
		1, 0
	);
	@:forward var text = new TextStyle();	
	public function new() {
		text.color = 0x888888;
	}
}

class InputStyle extends ComponentStyle {
	@:bindable var width = Rel(1);
	@:bindable var normal = Draw(
		Plain(0xFFFFFF, 1), 
		Linear([0xDDDDDD, 0xCCCCCC, 0x999999, 0x888888], [.5, .5, .5, .5], [0x00, 0x10, 0xEF, 0xFF], -Math.PI / 2),
		1, 0, 1
	);
	@:bindable var hover = Draw(
		Plain(0xFFFFFF, 1), 
		Linear([0xDDDDDD, 0xCCCCCC, 0x999999, 0x888888], [1, 1, 1, 1], [0x00, 0x10, 0xEF, 0xFF], -Math.PI / 2),
		1, 0, 1
	);	
	@:bindable var focus = Draw(
		Plain(0xFFFFFF, 1), 
		Linear([0xBBDDFF, 0xAACCEE, 0x7799DD, 0x6688CC], [1, 1, 1, 1], [0x00, 0x10, 0xEF, 0xFF], -Math.PI / 2),
		1, 0, 1
	);
	@:bindable var disabled = new DisabledInputStyle();
	@:forward var text = new TextStyle();
}
class Input extends UIComponent<Sprite, InputStyle> {
	
	@:bindable @:prop(tf.text, tf.text = param == null ? '' : param) var text:String;
	
	var tf = new TextField();
	
	@:bindable private var focused = false;
	@:bindable private var hovered = false;
	
	@:bindable var enabled = true;
	
	@:cache(enabled ? focused ? style.focus : hovered ? style.hover : style.normal : style.disabled.skin) private var curSkin:Skin;
	@:cache(enabled ? style.toNative() : style.disabled.toNative()) private var curFormat:TextFormat;
	
	public function new() {
		super(new Sprite(), new InputStyle());
		view.addChild(tf);
		tf.multiline = false;
		tf.type = TextFieldType.INPUT;
		tf.addEventListener(Event.CHANGE, function (_) {
			bindings.byString.fire('text');
		});
		tf.addEventListener(FocusEvent.FOCUS_IN, function (_) focused = true);
		tf.addEventListener(FocusEvent.FOCUS_OUT, function (_) focused = false);
		view.addEventListener(MouseEvent.ROLL_OVER, function (_) hovered = true);
		view.addEventListener(MouseEvent.ROLL_OUT, function (_) hovered = false);
		bindSkin();
		bindFormat();
	}
	function bindFormat() updateFormat.bind(curFormat)
	function bindSkin() updateSkin.bind(curSkin)
	
	function updateFormat(fmt) {
		tf.defaultTextFormat = fmt;
		tf.setTextFormat(fmt);
	}
	function updateSkin(_) uponRender(doRender)
	override function calcHMin() return ResizableComponent.calcMin(style.width)
	override function calcHWeight() return ResizableComponent.calcWeight(style.width)
	override function calcVMin() {
		curFormat;
		return tf.getLineMetrics(0).height + 4;//I just love good apis
	}
	override function redraw(width, height) {
		super.redraw(width, height);
		tf.width = width;
		tf.height = height;
		curSkin.draw(view, width, height);
		view.mouseEnabled = view.mouseChildren = enabled;//This happens to work, because the skin depends on enabled already
	}
}
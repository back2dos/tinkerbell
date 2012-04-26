package tink.ui.text;

import flash.filters.DropShadowFilter;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import haxe.Json;
import tink.ui.core.UIComponent;
import tink.ui.core.UIPaneBase;
import tink.ui.style.Style;
import flash.events.Event;
import flash.events.FocusEvent;
import tink.ui.style.Skin;

using tink.reactive.bindings.BindingTools;
using tink.ui.style.Skin;
/**
 * ...
 * @author back2dos
 */

class InputStyle extends ComponentStyle {
	@:bindable var width = Rel(1);
	@:bindable var normal = Draw(
		Linear([0xFFFFFF, 0xEEEEEE], [1, 1], [0x00, 0xFF], -Math.PI / 4 * 3), 
		Linear([0xBBBBBB, 0xAAAAAA, 0x999999, 0x888888], [1, 1, 1, 1], [0x00, 0x10, 0xEF, 0xFF], -Math.PI / 4 * 7)
	);
	@:bindable var focus = Draw(
		Linear([0xFFFFFF, 0xEEEEEE], [1, 1], [0x00, 0xFF], -Math.PI / 4 * 3), 
		Linear([0x99AAFF, 0x8899DD, 0x7788CC, 0x6677BB], [1, 1, 1, 1], [0x00, 0x10, 0xEF, 0xFF], -Math.PI / 4 * 7),
		2
	);
	@:bindable var fontFamily = '_sans';
	@:bindable var fontSize = 12;
	@:bindable var textColor = 0x000000;
}
 
class Input extends UIComponent<Sprite, InputStyle> {
	
	@:bindable @:prop(tf.text, tf.text = param == null ? '' : param) var text:String;
	
	var tf = new TextField();
	
	@:bindable private var focused = false;
	@:cache(focused ? style.focus : style.normal) private var curSkin:Skin;
	@:cache(new TextFormat(style.fontFamily, style.fontSize, style.textColor)) private var curFormat:TextFormat;
	public function new() {
		super(new Sprite(), new InputStyle());
		view.addChild(tf);
		//tf.background = true;
		tf.multiline = false;
		tf.type = TextFieldType.INPUT;
		//tf.defaultTextFormat = new TextFormat('_sans', 12);
		tf.addEventListener(Event.CHANGE, function (_) {
			bindings.fire('text');
		});
		tf.addEventListener(FocusEvent.FOCUS_IN, function (_) focused = true);
		tf.addEventListener(FocusEvent.FOCUS_OUT, function (_) focused = false);
		
		updateSkin.bindExpr(curSkin);
		
		bindFormat();
	}
	function bindFormat() {
		updateFormat.bindExpr(curFormat);
	}
	function updateFormat(fmt) {
		tf.defaultTextFormat = fmt;
		tf.setTextFormat(fmt);
	}
	function updateSkin(_) uponRender(doRender)
	override function calcHMin() return ResizableComponent.calcMin(style.width)
	override function calcHWeight() return ResizableComponent.calcWeight(style.width)
	override function calcVMin() {
		return tf.getLineMetrics(0).height + 4;//I just love good apis
	}
	override function redraw(width, height) {
		super.redraw(width, height);
		tf.width = width;
		tf.height = height;
		curSkin.draw(view, width, height);
	}
}
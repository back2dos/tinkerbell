package tink.ui.text;

import flash.filters.DropShadowFilter;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

import tink.ui.core.UIComponent;
import tink.ui.style.Style;
/**
 * ...
 * @author back2dos
 */

typedef LabelStyle = ComponentStyle;

class Label extends UIComponent<TextField, LabelStyle> {
	public var text(default, set_text):String;
	
	public function new(?text:String) {
		super(new TextField(), new LabelStyle());
		view.autoSize = TextFieldAutoSize.LEFT;
		view.selectable = false;
		view.defaultTextFormat = new TextFormat('_sans', 12, 0x222222);
		view.filters = [
			//new DropShadowFilter(1, 225, 0x000000, .25, 1, 1, 1, 3),
			new DropShadowFilter(1, 45, 0xFFFFFF, 1, 1, 1, 1, 3),
		];
		this.text = text;
	}
	
	@:bindable('hmin') override private function calcHMin() return view.width
	@:bindable('vmin') override private function calcVMin() return view.height
	
	function set_text(param) {
		var w0 = view.width,
			h0 = view.height;
		this.text = param;
		view.text = if (param == null) '' else param;
		if (w0 != view.width) this.bindings.fire('hmin');
		if (h0 != view.height) this.bindings.fire('vmin');
		return param;
	}
}
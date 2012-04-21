package tink.ui.text;

import flash.text.TextField;
import flash.text.TextFieldAutoSize;

import tink.ui.core.UIComponent;
import tink.ui.style.Style;
/**
 * ...
 * @author back2dos
 */

class Label extends UIComponent<TextField, ComponentStyle> {
	public var text(default, set_text):String;
	public function new(?text:String = '') {
		super(new TextField(), new ComponentStyle());
		view.autoSize = TextFieldAutoSize.LEFT;
		view.selectable = false;
		this.text = text;
	}
	@:bindable('hmin') override private function calcHMin() return view.width
	@:bindable('vmin') override private function calcVMin() return view.height
	
	function set_text(param) {
		var w0 = view.width,
			h0 = view.height;
		this.text = view.text = if (param == null) '' else param;
		if (w0 != view.width) this.bindings.fire('hmin');
		if (h0 != view.height) this.bindings.fire('vmin');
		return param;
	}
}
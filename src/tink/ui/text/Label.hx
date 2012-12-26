package tink.ui.text;

import flash.filters.BitmapFilter;
import flash.filters.DropShadowFilter;
import flash.text.Font;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

import tink.ui.core.UIComponent;
import tink.ui.style.Style;

using tink.reactive.bindings.BindingTools;

class LabelStyle extends ComponentStyle {
	@:forward var textStyle = new TextStyle();
	@:bindable var bevel = 1.0;
}

class Label extends UIComponent<TextField, LabelStyle> {
	public var text(default, set_text):String;
	
	public function new(?text:String) {
		super(new TextField(), new LabelStyle());
		view.autoSize = TextFieldAutoSize.LEFT;
		view.selectable = false;
		this.text = text;
		
		view.bind(filters, calcFilters());
		updateFormat.bind(style.toNative());
		//view.bind(embedFonts, style.embed);
	}
	function updateFormat(t:TextFormat) {
		view.setTextFormat(view.defaultTextFormat = t);
	}
	function calcFilters():Array<BitmapFilter> {
		return [
			new DropShadowFilter(this.style.bevel, 45, 0xFFFFFF, 1, 1, 1, this.style.bevel, 3),
			new DropShadowFilter(this.style.bevel, 225, 0, .1, 1, 1, this.style.bevel, 3)
		];
	}
	@:bindable('hmin') override private function calcHMin() return view.width
	@:bindable('vmin') override private function calcVMin() return view.height
	
	function set_text(param) {
		var w0 = view.width,
			h0 = view.height;
		this.text = param;
		view.text = if (param == null) '' else param;
		if (w0 != view.width) this.bindings.byString.fire('hmin');
		if (h0 != view.height) this.bindings.byString.fire('vmin');
		return param;
	}
}
package tink.ui.text;

import flash.filters.DropShadowFilter;
import flash.text.TextField;
import flash.text.TextFieldType;
import tink.ui.core.UIComponent;
import tink.ui.style.Style;
import flash.events.Event;
/**
 * ...
 * @author back2dos
 */

class Input extends UIComponent<TextField, ComponentStyle> {
	@:bindable @:prop(view.text, view.text = param == null ? '' : param) var text:String;
	public function new() {
		super(new TextField(), new ComponentStyle());
		view.background = true;
		view.multiline = false;
		view.filters = [new DropShadowFilter(1, 45, 0, .5, 4, 4, 1, 3, true)];
		view.width = 100;
		view.height = 20;		
		view.type = TextFieldType.INPUT;
		view.addEventListener(Event.CHANGE, function (_) {
			bindings.fire('text');
		});
	}
	override function calcHMin() return view.width
	override function calcVMin() return view.height
}
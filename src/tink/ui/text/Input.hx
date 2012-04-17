package tink.ui.text;

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
	//@:prop(bindings.bind('text', view.text), bindings.fire('text', view.text = param)) var text:String;
	@:bindable @:prop(view.text, view.text = param == null ? '' : param) var text:String;
	public function new() {
		super(new TextField(), new ComponentStyle());
		view.background = view.border = true;
		view.multiline = false;
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
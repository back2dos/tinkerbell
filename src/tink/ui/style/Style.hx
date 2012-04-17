package tink.ui.style;

import tink.lang.Cls;
import tink.ui.core.Pair;
import tink.ui.style.Skin;
/**
 * ...
 * @author back2dos
 */

interface Style {
	var marginLeft(dynamic, null):Float;
	var marginTop(dynamic, null):Float;
	var marginBottom(dynamic, null):Float;
	var marginRight(dynamic, null):Float;
	var hAlign(dynamic, null):Float;
	var vAlign(dynamic, null):Float;
}
class ComponentStyle implements Cls, implements Style {
	@:bindable var marginLeft = .0;
	@:bindable var marginTop = .0;
	@:bindable var marginBottom = .0;
	@:bindable var marginRight = .0;
	@:bindable var hAlign = .5;
	@:bindable var vAlign = .5;
	public function new() {}	
}
class PaneStyle extends ComponentStyle {
	@:bindable var skin = Draw(Plain(0x808080, .25), Plain(0));
}
class ContainerStyle extends PaneStyle {
	@:bindable var paddingLeft = 8.0;
	@:bindable var paddingTop = 8.0;
	@:bindable var paddingBottom = 8.0;
	@:bindable var paddingRight = 8.0;
	@:bindable var spacing = 2.0;
	@:bindable var flow = Flow.Down;
}
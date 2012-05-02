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
class Frame implements Cls {
	@:bindable var top = .0;
	@:bindable var left = .0;
	@:bindable var bottom = .0;
	@:bindable var right = .0;
	@:prop([top, right, bottom, left], expand(param)) var all:Array<Float>;
	public function new() {}
	function expand(a:Array<Float>) {		
		switch (a.length) {
			case 1: top = left = bottom = right = a[0];
			case 2: top = bottom = a[0]; right = left = a[1];
			case 3: top = a[0]; right = left = a[1]; bottom = a[2];
			case 4: top = a[0]; right = a[1]; bottom = a[2]; left = a[3];
			default: throw 'invalid number of values: ' + a.length;
		}
		return a;
	}
}
class ComponentStyle implements Cls, implements Style {
	@:bindable var marginLeft = .0;
	@:bindable var marginTop = .0;
	@:bindable var marginBottom = .0;
	@:bindable var marginRight = .0;
	@:bindable var hAlign = .5;
	@:bindable var vAlign = .5;
	public function new() { }
}
enum Size {
	Const(pt:Float);
	Rel(weight:Float);
}
class ResizableStyle extends ComponentStyle {
	@:bindable var width = Rel(1);
	@:bindable var height = Rel(1);
}
class PaneStyle extends ResizableStyle {
	@:bindable var skin = Draw(
		Linear([0xEEEEEE, 0xCCCCCC], [1, 1], [0x00, 0xFF], -Math.PI / 4 * 3), 
		Linear([0xBBBBBB, 0xAAAAAA, 0x999999, 0x888888], [1, 1, 1, 1], [0x00, 0x10, 0xEF, 0xFF], -Math.PI / 4 * 7)
	);
}
class ContainerStyle extends PaneStyle {
	//@:bindable var paddingLeft = .0;
	//@:bindable var paddingTop = .0;
	//@:bindable var paddingBottom = .0;
	//@:bindable var paddingRight = .0;
	@:read var padding = new Frame();
	@:bindable var spacing = .0;
	@:bindable var flow = Flow.Down;
}
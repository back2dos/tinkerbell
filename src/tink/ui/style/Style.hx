package tink.ui.style;

import flash.display.BitmapData;
import flash.geom.Rectangle;
import flash.geom.Rectangle;
import tink.lang.Cls;
import tink.ui.core.Pair;
import tink.ui.style.Skin;
/**
 * ...
 * @author back2dos
 */

interface Style {
	var margin(get_margin, null):Frame;
	var hAlign(get_hAlign, null):Float;
	var vAlign(get_vAlign, null):Float;
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
	public inline function offset(h) {
		return h ? left : top;
	}
	public inline function total(h) {
		return h ? left + right : top + bottom;
	}
}
class ComponentStyle implements Cls, implements Style {
	@:read var margin = new Frame();
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
@:bitmap("skin.png") 
class PaneSkin extends BitmapData {
	//static public var SKIN = nme.Assets.getBitmapData('assets/skin.png');
	static public var SKIN = new PaneSkin(100, 100);
}
class PaneStyle extends ResizableStyle {
	@:bindable var skin = Draw(Plain(0xF0F0F0, 1), Plain(0xBBBBBB, 1), .5, 0);
	//@:bindable var skin = Draw(
		//Linear([0xEEEEEE, 0xCCCCCC], [1, 1], [0x00, 0xFF], -Math.PI / 4 * 3), 
		//Linear([0xBBBBBB, 0xAAAAAA, 0x999999, 0x888888], [1, 1, 1, 1], [0x00, 0x10, 0xEF, 0xFF], -Math.PI / 4 * 7),
		//1,1
	//);
	//@:bindable var skin = Bitmap(
		//PaneSkin.SKIN, 
		//PaneSkin.SKIN.rect, 
		//new Rectangle(6, 4, 76, 16),
		//new Rectangle(3, 1, 82, 22) 
	//);
}
class ContainerStyle extends PaneStyle {
	@:read var padding = new Frame();
	@:bindable var spacing = .0;
	@:bindable var flow = Flow.South;
}
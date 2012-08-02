package tink.ui.core;

import flash.display.Sprite;
import flash.display.DisplayObject;
import flash.filters.DropShadowFilter;
import tink.ui.style.Skin;
import tink.ui.style.Style;

using tink.ui.style.Skin;
using tink.reactive.bindings.BindingTools;
/**
 * ...
 * @author back2dos
 */

class ResizableComponent<V:DisplayObject, S:ResizableStyle> extends UIComponent<V, S> {
	function new(view, style) {
		super(view, style);
	}
	override function calcHMin() return calcMin(style.width)
	override function calcVMin() return calcMin(style.height)
	
	override function calcHWeight() return calcWeight(style.width)
	override function calcVWeight() return calcWeight(style.height)
	
	static public function calcMin(size:Size)
		return switch (size) {
			case Const(px): px;
			case Rel(_): .0;
		}
	
	static public function calcWeight(size:Size)
		return switch (size) {
			case Const(_): .0;
			case Rel(weight): weight;
		}
}
class UIPaneBase<S:PaneStyle> extends ResizableComponent<Sprite, S> {
	function new(style) {
		super(new Sprite(), style);
		function updateSkin(_) uponRender(doRender);
		//updateSkin.bind(style.skin);
		updateSkin.bind(style.skin);
	}	
	override function redraw(width:Float, height:Float) {
		style.skin.draw(view, width, height);
	}
}
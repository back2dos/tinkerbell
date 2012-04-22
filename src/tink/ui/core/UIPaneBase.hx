package tink.ui.core;

import flash.display.Sprite;
import flash.filters.DropShadowFilter;
import tink.ui.style.Style;

using tink.ui.style.Skin;
using tink.reactive.bindings.BindingTools;
/**
 * ...
 * @author back2dos
 */


class UIPaneBase<S:PaneStyle> extends UIComponent<Sprite, S> {
	function new(style) {
		super(new Sprite(), style);
		function updateSkin(_) uponRender(doRender);
		updateSkin.bindExpr(style.skin);
	}
	
	override function calcHWeight() return 1.0		
	override function calcVWeight() return 1.0
	
	override function redraw(width:Float, height:Float) {
		style.skin.draw(view, width, height);
	}
}
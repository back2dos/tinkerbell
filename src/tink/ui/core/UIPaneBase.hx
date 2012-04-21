package tink.ui.core;

import flash.display.Sprite;
import flash.filters.DropShadowFilter;
import tink.ui.style.Style;

using tink.ui.style.Skin;

/**
 * ...
 * @author back2dos
 */


class UIPaneBase<S:PaneStyle> extends UIComponent<Sprite, S> {
	function new(style) {
		super(new Sprite(), style);
		view.filters = [new DropShadowFilter(1, 45, 0, .5, 4, 4, 1, 3)];
	}
	
	override function calcHWeight() return 1.0		
	override function calcVWeight() return 1.0
	//override function calcHWeight() 
		//return switch (style.width) {
			//case Rel(weight): weight;
			//default: 0;
		//}
		//
	//override function calcVWeight() 
		//return switch (style.height) {
			//case Rel(weight): weight;
			//default: 0;
		//}
	
	override function redraw(width:Float, height:Float) {
		style.skin.draw(view.graphics, width, height);
	}
}
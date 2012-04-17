package tink.ui.core;

import flash.display.Sprite;
import tink.ui.style.Style;

using tink.ui.style.Skin;

/**
 * ...
 * @author back2dos
 */


class UIPaneBase<S:PaneStyle> extends UIComponent<Sprite, S> {
	function new(style) {
		super(new Sprite(), style);
	}
	function redraw(width:Float, height:Float) {
		style.skin.draw(view.graphics, width, height);
	}
}
package tink.ui.core;

import flash.display.Sprite;
import flash.filters.DropShadowFilter;
import tink.devtools.Debug;
import tink.reactive.bindings.BindableArray;
import tink.ui.core.Metrics;
import tink.ui.style.Style;

using tink.ui.core.Metrics;
using tink.ui.style.Skin;
/**
 * ...
 * @author back2dos
 */
 
class UIContainer extends UIPaneBase<ContainerStyle> {
	var children = new BindableArray<UILeaf>();	
	@:cache({
		var a = [];
		for (c in children)
			a.push(c.getMetrics());
		a;
	}) 
	var childMetrics:Array<Metrics>;	
	public function new() {
		super(new ContainerStyle());
	}
	public inline function addChild(child:UILeaf) {
		addChildAt(child, 0xFFFF);
	}
	public function addChildAt(child:UILeaf, pos:Int) {
		children.remove(child);
		if (pos < 0)
			pos = 0;
		else if (pos > children.length) 
			pos = children.length;
		view.addChild(child.getView());
		children.insert(pos, child);
	}
	public function removeChild(child:UILeaf) {
		view.removeChild(child.getView());
		children.remove(child);
	}
	function getMin(h) {
		for (c in children) c.getMetrics().getAlign(h);
		return childMetrics.min(isLong(h), h, style.spacing);
	}
	
	override function calcHMin() 
		return Math.max(super.calcHMin(), style.padding.left + style.padding.right + getMin(true))
		
	override function calcVMin() 
		return Math.max(super.calcVMin(), style.padding.top + style.padding.bottom + getMin(false))
	
	function isLong(h:Bool) {
		return
			switch (style.flow) {
				case East: h;
				case South: !h;
				case Stack: false;
			}		
	}
	override function setDim(h:Bool, dim:Float) {
		super.setDim(h, dim);
		var offset = h ? style.padding.left : style.padding.top;
		dim -= h ? (style.padding.left + style.padding.right + hMargin()) : (style.padding.top + style.padding.bottom + vMargin());
		childMetrics.arrange(h, isLong(h), offset , dim, style.spacing);
	}
}
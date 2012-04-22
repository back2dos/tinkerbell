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
		
	public function new() {
		super(new ContainerStyle());
	}
	public inline function addChild(child:UILeaf) {
		addChildAt(child, 0xFFFF);
	}
	public function addChildAt(child:UILeaf, pos:Int) {
		view.addChild(child.getView());
		children.remove(child);
		if (pos > children.length) 
			pos = children.length;
		children.insert(pos, child);
	}
	public function removeChild(child:UILeaf) {
		view.removeChild(child.getView());
		children.remove(child);
	}
	function getMin(h) return getChildMetrics().min(isLong(h), h, style.spacing)
	
	override function calcHMin() 
		return style.paddingLeft + style.paddingRight + getMin(true)
		
	override function calcVMin() 
		return style.paddingTop + style.paddingBottom + getMin(false)
	
	function getChildMetrics():Iterable<Metrics> {
		return {
			iterator: function () {
				var it = children.iterator();
				return {
					next: function () return it.next().getMetrics(),
					hasNext: function () return it.hasNext()
				}
			}
		}
	}
	function isLong(h:Bool) {
		return
			switch (style.flow) {
				case Right: h;
				case Down: !h;
				case Stack: false;
			}		
	}
	override function setDim(h:Bool, dim:Float) {
		super.setDim(h, dim);
		var offset = h ? style.paddingLeft : style.paddingTop;
		dim -= h ? (style.paddingLeft + style.paddingRight + hMargin()) : (style.paddingTop + style.paddingBottom + vMargin());
		getChildMetrics().arrange(h, isLong(h), offset , dim, style.spacing);
	}
}
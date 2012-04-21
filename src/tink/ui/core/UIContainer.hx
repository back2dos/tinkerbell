package tink.ui.core;

import flash.display.Sprite;
import flash.filters.DropShadowFilter;
import tink.devtools.Debug;
import tink.reactive.bindings.BindableArray;
import tink.ui.core.Metrics;
import tink.ui.style.Style;
import flash.events.MouseEvent;
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
		view.addEventListener(MouseEvent.CLICK, function (e:MouseEvent) {
			if (e.target == view)
				Debug.log(_hMin, _vMin);
		});
	}
	public function addChild(child:UILeaf) {
		var view = child.getView();
		children.remove(child);
		children.push(child);
		this.view.addChild(view);
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
		dim -= h ? (style.paddingLeft + style.paddingRight) : (style.paddingTop + style.paddingBottom);
		getChildMetrics().arrange(h, isLong(h), offset , dim, style.spacing);
	}
}
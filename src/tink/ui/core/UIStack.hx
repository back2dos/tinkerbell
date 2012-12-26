package tink.ui.core;

import flash.display.Sprite;
import tink.reactive.bindings.BindableArray;
import tink.ui.core.Metrics;

import tink.ui.core.UILeaf;
import tink.ui.core.UIContainer;
import tink.ui.style.Style;
import tink.ui.style.Skin;

using tink.ui.core.Metrics;
using tink.reactive.bindings.BindingTools;

class UIStack extends UIPaneBase<ContainerStyle> {	
	@:prop(
		if (param < 0) 0 
		else if (param >= children.length) children.length - 1 
		else param
	)
	@:bindable 
	var index = 0;
	
	var children = new BindableArray<UILeaf>();	
	@:cache({
		var a = [];
		for (c in children)
			a.push(c.getMetrics());
		a;
	}) 
	private var childMetrics:Array<Metrics>;	
	public function new() {
		super(new ContainerStyle());
		refresh.bind(
			for (i in 0...children.length) {
				var c = children.get(i);
				if (i == index) view.addChild(c.getView());
				else if (view.contains(c.getView())) view.removeChild(c.getView());
			}
		);
	}
	function refresh<A>(a:A):Void {}
	public inline function addChild(child:UILeaf) {
		addChildAt(child, 0xFFFF);
	}
	public function addChildAt(child:UILeaf, pos:Int) {
		children.remove(child);
		if (pos < 0)
			pos = 0;
		else if (pos > children.length) 
			pos = children.length;
		children.insert(pos, child);
	}
	public function removeChild(child:UILeaf) {
		if (view.contains(child.getView()))
			view.removeChild(child.getView());
		children.remove(child);
	}
	function getMin(h) {
		for (c in children) c.getMetrics().getAlign(h);
		return childMetrics.min(false, h, style.spacing);
	}
	public function iterator() return children.iterator()
	
	override function calcHMin() 
		return Math.max(super.calcHMin(), style.padding.left + style.padding.right + getMin(true))
		
	override function calcVMin() 
		return Math.max(super.calcVMin(), style.padding.top + style.padding.bottom + getMin(false))
	
	override function setDim(h:Bool, dim:Float) {
		super.setDim(h, dim);
		var offset = h ? style.padding.left : style.padding.top;
		dim -= h ? (style.padding.left + style.padding.right + hMargin()) : (style.padding.top + style.padding.bottom + vMargin());
		childMetrics.arrange(h, false, offset , dim, style.spacing);
	}	
}
package tink.ui.core;

import tink.collections.maps.FunctionMap;
import tink.collections.queues.ArrayQueue;
import tink.collections.queues.UniqueQueue;
import tink.ui.core.Pair;
import tink.lang.Cls;
import tink.ui.style.Style;
import tink.ui.core.Metrics;

using tink.ui.core.Metrics;

typedef NativeView = flash.display.DisplayObject;

class UIComponent<V:NativeView, S:Style> implements Cls, implements UILeaf {
	var metrics:Metrics;
	var width = .0;
	var height = .0;
	var x = .0;
	var y = .0;
	
	@:cache(hMargin() + calcHMin()) private var _hMin:Float;
	@:cache(vMargin() + calcVMin()) private var _vMin:Float;
		
	var view:V;
	public var style(default, null):S;
	
	function new(view, style) {
		this.view = view;
		this.style = style;
		this.metrics = new Metrics(
			new BindingPair(get__hMin, get__vMin),
			new BindingPair(
				function () return this.style.hAlign, 
				function () return this.style.vAlign
			),
			new BindingPair(calcHWeight, calcVWeight),
			setPos,
			setDim
		);
	}
	
	function calcHMin() return .0
	function calcVMin() return .0
	function calcHWeight() return .0
	function calcVWeight() return .0
	
	inline function hMargin() return style.margin.left + style.margin.right
	inline function vMargin() return style.margin.top + style.margin.bottom
	
	public function getView():NativeView return view
	public function getMetrics():Metrics return metrics
	
	function updateX() view.x = x
	function updateY() view.y = y
	
	function setPos(h:Bool, pos:Float) {
		if (h) {
			x = pos + style.margin.left;
			uponRender(updateX);
		}
		else {
			y = pos + style.margin.top;
			uponRender(updateY);
		}
	}
	function setDim(h:Bool, dim:Float) {
		var changed = h ? width != dim : height != dim;//not pretty but good enough
		if (h) width = dim;
		else height = dim;
		
		if (changed)
			uponRender(doRender);
	}
	
	inline function uponRender(f) 
		renderTodos.add(f)
			
	function doRender() 
		redraw(width - hMargin(), height - vMargin())
		
	function redraw(width:Float, height:Float) { }
	
	static var renderTodos = new UniqueQueue(new FunctionMap());
}
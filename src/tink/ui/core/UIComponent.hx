package tink.ui.core;

import flash.display.DisplayObject;
import flash.events.Event;
import tink.collections.maps.FunctionMap;
import tink.collections.queues.ArrayQueue;
import tink.collections.queues.UniqueQueue;
import tink.ui.core.Pair;
import tink.lang.Cls;
import tink.ui.style.Style;
import tink.ui.core.Metrics;

using tink.ui.core.Metrics;

/**
 * ...
 * @author back2dos
 */

class UIComponent<V:DisplayObject, S:Style> implements Cls, implements UILeaf {
	var metrics:Metrics;
	var width = .0;
	var height = .0;
	var x = .0;
	var y = .0;
	
	@:cache(this.style.marginLeft + this.style.marginRight + calcHMin()) private var _hMin = .0;
	@:cache(this.style.marginTop + this.style.marginBottom + calcVMin()) private var _vMin = .0;
		
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
	
	public function getView():DisplayObject return view
	public function getMetrics():Metrics return metrics
	
	function updateX() view.x = x
	function updateY() view.y = y
	function setPos(h:Bool, pos:Float) {
		if (h) {
			x = pos + style.marginLeft;
			uponRender(updateX);
		}
		else {
			y = pos + style.marginTop;
			uponRender(updateY);
		}
	}
	function setDim(h:Bool, dim:Float) {
		if (h) width = dim;
		else height = dim;
		uponRender(doRender);
	}
	
	inline function uponRender(f) 
		renderTodos.add(f)
			
	function doRender() 
		redraw(width, height)
		
	function redraw(width:Float, height:Float) { }
	
	static var renderTodos = new UniqueQueue(new FunctionMap());
}
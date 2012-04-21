package tink.ui.core;

import flash.display.Stage;
import flash.events.Event;
import flash.Lib;
import tink.reactive.bindings.Binding;

/**
 * ...
 * @author back2dos
 */

class UILayoutRoot extends UIContainer {
	var stage:Stage;
	var watch:Watch<Void>;
	public function new(s) {
		super();
		this.stage = s;
		stage.addEventListener(Event.ENTER_FRAME, function (_) stage.invalidate());
		stage.addEventListener(Event.RESIZE, function (_) handleResize());
		stage.addEventListener(Event.RENDER, function (_) doRenderJobs());
		stage.addChild(view);		
		watch = new Watch(function () {
			style.hAlign;
			style.vAlign;
			_hMin;
			_vMin;
		});
		watch.watch(callback(uponRender, handleResize));
		handleResize();
	}
	function doRenderJobs() {
		var todo = UIComponent.renderTodos;
		while (!todo.isEmpty()) 
			todo.get()();
	}
	function handleResize() {
		watch.value;
		var w = Math.max(stage.stageWidth - 40, _hMin),
			h = Math.max(stage.stageHeight - 40, _vMin);
			
		setPos(true, .5 * (stage.stageWidth - w));
		setPos(false, .5 * (stage.stageHeight - h));
		
		setDim(true, w);
		setDim(false, h);
	}
}
package tink.ui.core;

import flash.display.Stage;
import flash.events.Event;
import flash.Lib;
import tink.ui.style.Flow;

import tink.ui.style.Style;
import tink.reactive.bindings.Binding;

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
		style.flow = Flow.Layers;
		//style.skin = PaneStyle.LIGHT_SKIN;
	}
	function doRenderJobs() {
		var todo = UIComponent.renderTodos;
		while (!todo.isEmpty()) 
			todo.get()();
	}
	function handleResize() {
		watch.value;
		var w = Math.max(stage.stageWidth, _hMin),
			h = Math.max(stage.stageHeight, _vMin);
			
		setPos(true, Math.round(.5 * (stage.stageWidth - w)));
		setPos(false, Math.round(.5 * (stage.stageHeight - h)));
		
		setDim(true, w);
		setDim(false, h);
	}
}

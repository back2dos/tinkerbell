package ;

import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.Lib;
import flash.display.Sprite;
import tink.tween.Tweener;
import tink.ui.style.Skin;
import tink.ui.style.Style;

import haxe.Timer;

import tink.devtools.Debug;
import tink.devtools.Lorem;

import tink.reactive.bindings.BindableArray;
import tink.ui.core.UIContainer;
import tink.ui.core.UILayoutRoot;
import tink.ui.style.Flow;
import tink.ui.text.Label;
import tink.ui.text.Input;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.geom.Rectangle;
import flash.system.System;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.events.MouseEvent;

import tink.ui.controls.Button;
import tink.ui.controls.ScrollBar;

using tink.reactive.bindings.BindingTools;
using Lambda;
using StringTools;

class Main {
	static function main() {
		var stage = Lib.current.stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;		
		var s = new UILayoutRoot(stage);
		Timer.delay(callback(run, s), 10);
		//stage.addChild(new Stats(250, 100));
	}
	static function run(s:UILayoutRoot) {		
		
		var cols = new UIContainer();
		cols.style.flow = Flow.Right;
		var l = null;
		var inputs = new BindableArray();
		var a = 'hello world this is so awesome!'.split(' ');
		
		function addPart() {
			var c = new UIContainer();
			cols.addChild(c);
			for (j in 0...2)
				c.addChild(l = new Label(Lorem.text.sentence(5)));
			var input = new Input();
			input.text = a.shift();
			c.addChild(input);
			inputs.push(input);
			var btn = new Button();
			
			c.addChild(btn);
			
			btn.caption = input.text;
			
			return btn;
		}
		var add = new Button();
		
		add.caption = 'Gimme more!';
		add.style.height = Rel(0);
		add.style.width = Rel(0);
		add.click.watch(function (_) addPart());
		s.addChild(add);
		s.addChild(cols);
		var bar = new ScrollBar();
		s.addChild(bar);
		bar.style.horizontal = false;
		bar.style.thickness = 50;
		addPart();
		//btn.getView().addEventListener(Event.ENTER_FRAME, function (_) btn.style.height = btn.style.height);
		
		var out = new Label('magic here!');
		s.addChild(out);
		out.text.bindExpr({
			var a = [inputs.length+' < Magic here!'];
			for (input in inputs) 
				a.push(input.text.trim());
			a.join(' ');
		});
		var h = true;
		out.getView().addEventListener(MouseEvent.CLICK, function (_) {
			h = !h;
			cols.style.flow = h ? Flow.Right : Flow.Down;
		});
	}
}

typedef RenderStat = Stat->Void;
typedef RenderText = TextField->Void;
class Stats extends Sprite {
	var statWidth:Int;
	var statHeight:Int;
	var updaters:Array<Void->Void>;
	var texts:Array<TextField>;
	var maxMem:Int;
	public function new(width, height, ?maxMem = 500000000) {
		super();
		
		this.maxMem = maxMem;
		
		this.updaters = [];
		this.texts = [];
		this.fpsMeasured = [];
		this.fpsAverage = 0;
		
		this.statWidth = width;
		this.statHeight = height - 20;
		
		addStat(0x00FF00, renderFpsStat);
		addStat(0xFF00FF, renderMemStat);
		addMonitor(0xFF00FF, renderMemText);
		addMonitor(0x00FF00, renderFpsText);
		
		this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		this.graphics.beginFill(0, .5);
		this.graphics.drawRect(0, 0, width, height);
		this.graphics.beginFill(0, .5);
		this.graphics.drawRect(0, statHeight, width, 20);
		this.graphics.endFill();
		
		line(.50, .50);
		line(.25, .25);
		line(.75, .25);
		line(.125, .125);
		line(.375, .125);
		line(.625, .125);
		line(.875, .125);
	}
	
	public function addMonitor(color:UInt, render:RenderText) {
		var ret = new TextField();
		ret.defaultTextFormat = new TextFormat('_typewriter', 11, color);
		ret.selectable = false;
		ret.height = 20;
		var step = statWidth / texts.push(ret);
		addChild(ret).y = statHeight;
		for (i in 0...texts.length) {
			texts[i].x = i * step;
			texts[i].width = step;
		}
		updaters.push(callback(render, ret));
	}
	public function addStat(color:UInt, render:RenderStat) {
		var alpha = (color & 0xFF000000) >>> 24;
		if (alpha == 0) alpha = 0xFF;
		var barAlpha = Std.int(alpha * 0.25);
		color &= 0xFFFFFF;
		var ret = new Stat(statWidth, statHeight, color + (alpha << 24), color + (barAlpha << 24));
		this.addChild(ret);
		this.updaters.push(callback(render, ret));
		return ret;
	}
	private function line(relativeY:Float, weight) {
		this.graphics.lineStyle(1, 0xFFFFFF, weight);
		this.graphics.moveTo(0, relativeY * statHeight);
		this.graphics.lineTo(width-1, relativeY * statHeight);
	}
	function renderFpsStat(view:Stat) {
		var expected = 2000 / stage.frameRate;
		view.addValue(diff / expected);		
	}
	function renderMemStat(view:Stat) {
		view.addValue(System.totalMemory / maxMem);
	}
	function renderMemText(tf:TextField) {
		tf.text = 'Mem: ' + (Std.int(System.totalMemory / 1000) / 1000);
	}
	var fpsMeasured:Array<Float>;
	var fpsAverage:Float;
	var curFpsIndex:Int;
	static inline var MAX_COUNT = 50;
	function renderFpsText(tf:TextField):Void {
		var fps = 1000 / diff;
		if (!(fps < 1000)) return;
		var count = fpsMeasured.length;
		fpsAverage *= count;
		if (fpsMeasured.length == MAX_COUNT) {
			fpsAverage -= fpsMeasured[curFpsIndex];
			fpsMeasured[curFpsIndex] = fps;
			curFpsIndex += 1; curFpsIndex %= MAX_COUNT;
		}
		else count = fpsMeasured.push(fps);
		fpsAverage += fps; 
		fpsAverage /= count;
		//Debug.log(fps, fpsAverage, count);
		tf.text = 'FPS: ' + Math.round(fpsAverage * 10) / 10;
		//tf.text = 'FPS: ' + Math.round(fps) +' : ' +fpsAverage;
	}
	var last:Int;
	var diff:Int;
	private function onEnterFrame(e:Event):Void {
		var now = Lib.getTimer();
		diff = now - last;
		last = now;
		for (f in updaters) f();
	}
	
}
class Stat extends Bitmap {
	var spot:UInt;
	var bar:UInt;
	public function new(width, height, spot, bar) {
		this.spot = spot;
		this.bar = bar;
		super(new BitmapData(width, height, true, 0));
	}
	public function addValue(value:Float) {
		bitmapData.scroll( -1, 0);
		var y = Std.int(bitmapData.height * (1 - value));
		bitmapData.fillRect(new Rectangle(bitmapData.width - 2, y, 1, bitmapData.height - y), bar);
		bitmapData.setPixel32(bitmapData.width - 2, y, spot);
	}
}
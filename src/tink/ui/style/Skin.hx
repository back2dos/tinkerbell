package tink.ui.style;

import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Sprite;
import tink.devtools.Debug;

import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
 * ...
 * @author back2dos
 */

enum Skin {
	None;
	Draw(fill:DrawStyle, stroke:DrawStyle, ?thickness:Float, ?inset:Float, ?corner:Float);
	Bitmap(sheet:BitmapData, source:Rectangle, ?grid:Rectangle, ?actual:Rectangle);
}

enum DrawStyle {
	Empty;
	Plain(rgb:Int, alpha:Float);
	Linear(colors:Array<Int>, alphas:Array<Dynamic>, ratios:Array<Dynamic>, angle:Float);
}

class SkinTools {
	static public function draw(skin:Skin, surface:Sprite, w:Float, h:Float) {
		var g = surface.graphics;
		g.clear();
		switch (skin) {
			case None:
			case Draw(fill, stroke, thickness, inset, corner):
				if (thickness == null) thickness = 1;
				if (inset == null) inset = .5;
				var delta = (1 - inset) * thickness;
				var margin = 
					switch (stroke) {
						case Plain(rgb, alpha): 
							doFill(g, rgb, alpha);
							g.drawRoundRect( -delta, -delta, w + 2 * delta, h + 2 * delta, corner * 2 + 2 * delta);
							inset * thickness;
						case Linear(colors, alphas, ratios, angle):
							doLinear(g, colors, alphas, ratios, angle, w, h);
							g.drawRoundRect( -delta, -delta, w + 2 * delta, h + 2 * delta, corner * 2 + 2 * delta);
							inset * thickness;
						case Empty: 0;
					}
				switch (fill) {
					case Plain(rgb, alpha): doFill(g, rgb, alpha);
					case Linear(colors, alphas, ratios, angle):
						doLinear(g, colors, alphas, ratios, angle, w, h);
					case Empty:
				}
				
				g.drawRoundRect(margin, margin, w - 2 * margin, h - 2 * margin, Math.max(0, (corner - margin) * 2));
			case Bitmap(sheet, source, grid, actual):
				if (actual == null) actual = source;
				if (grid == null) grid = source;
				//S - source, T - target, t - top, l - left, b - bottom, r - right
				
				var tlS = rect(source.left, source.top, grid.left, grid.top);
				var tlT = rect(0, 0, tlS.right, tlS.bottom);
					tlT.offset(source.left - actual.left, source.top - actual.top);
					drawTexture(g, sheet, tlS, tlT);

				var trS = rect(grid.right, source.top, source.right, grid.top);
				var trT = rect(w - trS.width, 0, w, trS.bottom); 
					trT.offset(source.right - actual.right, source.top - actual.top);
					drawTexture(g, sheet, trS, trT);
					
				var blS = rect(source.left, grid.bottom, grid.left, source.bottom);
				var blT = rect(0, h - blS.height, blS.width, h);
					blT.offset(source.left - actual.left, source.bottom - actual.bottom);
					drawTexture(g, sheet, blS, blT);
					
				var brS = rect(grid.right, grid.bottom, source.right, source.bottom);
				var brT = rect(trT.left, blT.top, trT.right, blT.bottom);
					drawTexture(g, sheet, brS, brT);
				
				var tS = rect(tlS.right, tlS.top, trS.left, trS.bottom);
				var tT = rect(tlT.right, tlT.top, trT.left, trT.bottom);
					drawTexture(g, sheet, tS, tT);
				var bS = rect(blS.right, blS.top, brS.left, brS.bottom);
				var bT = rect(blT.right, blT.top, brT.left, brT.bottom);
					drawTexture(g, sheet, bS, bT);
				var lS = rect(tlS.left, tlS.bottom, blS.right, blS.top);
				var lT = rect(tlT.left, tlT.bottom, tlT.right, blT.top);
					drawTexture(g, sheet, lS, lT);
				var rS = rect(trS.left, trS.bottom, brS.right, brS.top);
				var rT = rect(trT.left, trT.bottom, brT.right, brT.top);
					drawTexture(g, sheet, rS, rT);
				
				var cS = rect(tlS.right, tlS.bottom, brS.left, brS.top);
				var cT = rect(tlT.right, tlT.bottom, brT.left, brT.top);
					drawTexture(g, sheet, cS, cT);				
		}
	}
	static inline function drawTexture(g:Graphics, sheet:BitmapData, source:Rectangle, target:Rectangle) {
		g.beginBitmapFill(sheet, fromTo(source, target));
		g.drawRect(target.x, target.y, target.width, target.height);		
	}
	static inline function fromTo(source:Rectangle, target:Rectangle) {
		var m = new Matrix();
		m.translate(-source.x, -source.y);
		m.scale(target.width / source.width, target.height / source.height);
		m.translate(target.x, target.y);
		return m;
	}
	static inline function rect(left:Float, top:Float, right:Float, bottom:Float) {
		return new Rectangle(left, top, right - left, bottom - top);
	}
	
	static function doLinear(g:Graphics, colors, alphas, ratios, angle, w, h) {
		var m = new Matrix();
		m.createGradientBox(w, h, angle, 0, 0);
		g.beginGradientFill(LINEAR, colors, alphas, ratios, m);
	}
	static function doFill(g:Graphics, rgb:Int, alpha:Float) {
		g.beginFill(rgb, alpha);
	}
}
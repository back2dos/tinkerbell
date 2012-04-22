package tink.ui.style;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.geom.Matrix;
import flash.geom.Rectangle;

/**
 * ...
 * @author back2dos
 */

enum Skin {
	None;
	Draw(fill:DrawStyle, stroke:DrawStyle);
}

enum DrawStyle {
	Empty;
	Plain(rgb:Int, alpha:Float);
	Linear(colors:Array<Int>, alphas:Array<Dynamic>, ratios:Array<Dynamic>, angle:Float);
	//Bitmap(sheet:BitmapData, source:Rectangle, scaleGrid:Rectangle);
}

class SkinTools {
	static public function draw(skin:Skin, surface:Sprite, w:Float, h:Float) {
		var g = surface.graphics;
		g.clear();
		switch (skin) {
			case None:
			case Draw(fill, stroke):
				var margin = 
					switch (stroke) {
						case Plain(rgb, alpha): 
							doFill(g, rgb, alpha);
							g.drawRect(0, 0, w, h);
							1;
						case Linear(colors, alphas, ratios, angle):
							doLinear(g, colors, alphas, ratios, angle, w, h);
							g.drawRect(0, 0, w, h);
							1;
						case Empty: 0;
					}
				switch (fill) {
					case Plain(rgb, alpha): doFill(g, rgb, alpha);
					case Linear(colors, alphas, ratios, angle):
						doLinear(g, colors, alphas, ratios, angle, w, h);
					case Empty:
				}
				g.drawRect(margin, margin, w - 2 * margin, h - 2 * margin);
		}
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
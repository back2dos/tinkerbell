package tink.ui.style;
import flash.display.Graphics;

/**
 * ...
 * @author back2dos
 */

enum Skin {
	Draw(fill:DrawStyle, ?stroke:DrawStyle);
}

enum DrawStyle {
	Plain(rgb:Int, ?alpha:Float);
}

class SkinDrawer {
	static public function draw(skin:Skin, g:Graphics, w:Float, h:Float) {
		switch (skin) {
			case Draw(fill, stroke):
				g.clear();
				switch (fill) {
					case Plain(rgb, alpha): doFill(g, rgb, alpha);
				}
				if (stroke != null)
					switch (stroke) {
						case Plain(rgb, alpha): 
							doStroke(g, rgb, alpha);
					}
				g.drawRect(0, 0, w, h);
		}
	}
	static function doFill(g:Graphics, rgb:Int, ?alpha:Float) {
		g.beginFill(rgb, alpha == null ? 1 : alpha);
	}
	static function doStroke(g:Graphics, rgb:Int, ?alpha:Float) {
		g.lineStyle(1, rgb, alpha == null ? 1 : alpha);
	}
}
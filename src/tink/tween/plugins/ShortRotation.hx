package tink.tween.plugins;
import flash.display.DisplayObject;
import flash.geom.Point;
import tink.tween.plugins.macros.PluginBase;

/**
 * ...
 * @author back2dos
 */

class ShortRotation extends PluginBase<DisplayObject> {
	override function init(end:Float):Float {
		//please forgive my laziness
		var start = target.rotation;
		while (start > end)
			start -= 360;
		return
			if (end - start > 180) 
				start + 360;
			else 
				start;
	}
	override function setValue(value:Float):Void {
		this.target.rotation = value;
	}
}
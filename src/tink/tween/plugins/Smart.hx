package tink.tween.plugins;
import flash.display.DisplayObject;
import tink.tween.plugins.PluginBase;

/**
 * ...
 * @author back2dos
 */
extern class Smart {
	static public inline function angle(start:Float, end:Float):Float {
		//please forgive my laziness
		while (start > end)
			start -= 360;
		return
			if (end - start > 180) 
				start + 360;
			else 
				start;		
	}
}
class AutoAlpha extends PluginBase<DisplayObject> {
	override function init(_):Float {
		return target.alpha;
	}
	override function setValue(value:Float) {
		target.visible = (target.alpha = value) > 0;
		return null;
	}
}

class ShortRotation extends PluginBase<DisplayObject> {
	override function init(end:Float):Float {
		return Smart.angle(target.rotation, end);
	}
	override function setValue(value:Float) {
		this.target.rotation = value;
		return null;
	}
}
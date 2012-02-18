package tink.tween.plugins;
import flash.display.DisplayObject;
import tink.tween.plugins.macros.PluginBase;

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
	override function setValue(value:Float):Void {
		target.visible = (target.alpha = value) > 0;
	}
}

class ShortRotation extends PluginBase<DisplayObject> {
	override function init(end:Float):Float {
		return Smart.angle(target.rotation, end);
	}
	override function setValue(value:Float):Void {
		this.target.rotation = value;
	}
}
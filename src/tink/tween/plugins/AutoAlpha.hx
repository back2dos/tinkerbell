package tink.tween.plugins;
import flash.display.DisplayObject;
import tink.tween.plugins.macros.PluginBase;

/**
 * ...
 * @author back2dos
 */

class AutoAlpha extends PluginBase<DisplayObject> {
	override function init(_):Float {
		return target.alpha;
	}
	override function setValue(value:Float):Void {
		target.visible = (target.alpha = value) > 0;
	}
}
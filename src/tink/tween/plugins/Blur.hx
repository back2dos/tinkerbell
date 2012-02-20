package tink.tween.plugins;
import flash.display.DisplayObject;
import flash.filters.BlurFilter;
import flash.utils.TypedDictionary;
import tink.collections.ObjectMap;
import tink.tween.plugins.PluginBase;
import tink.tween.Tween;

/**
 * ...
 * @author back2dos
 */

class BlurX extends PluginBase<DisplayObject> {
	override function init(_):Float {
		return Helper.getFilter(target).blurX;
	}
	override function setValue(value:Float):Null<TweenCallback> {
		Helper.modifyFilter(target, function (b) b.blurX = value);
		return null;
	}
}
class BlurY extends PluginBase<DisplayObject> {
	override function init(_):Float {
		return Helper.getFilter(target).blurY;
	}
	override function setValue(value:Float):Null<TweenCallback> {
		Helper.modifyFilter(target, function (b) b.blurY = value);
		return null;
	}
}

private class Helper {
	static public function getFilter(d:DisplayObject):BlurFilter {
		for (f in d.filters)
			if (Std.is(f, BlurFilter))
				return f;
		var ret = new BlurFilter(0, 0, 3);
		d.filters = d.filters.concat([ret]);
		return ret;
	}
	static public function modifyFilter(d:DisplayObject, modify:BlurFilter->Void) {
		var i = 0,
			filters = d.filters;
		for (f in filters) 
			if (Std.is(f, BlurFilter)) {
				modify(f);
				break;
			}
		d.filters = filters;
	}
}
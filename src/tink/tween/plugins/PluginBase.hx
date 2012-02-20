package tink.tween.plugins;
import tink.tween.Tween;

/**
 * ...
 * @author back2dos
 */

class PluginBase<T> implements Plugin<T> {
	var target:T;
	var start:Float;
	var delta:Float;
	@:final public function new(target:T, end:Float) {
		this.target = target;
		this.start = init(end);
		this.delta = end - start;
	}
	function init(end:Float):Float {
		return throw 'abstract';
	}
	function setValue(value:Float):Null<TweenCallback> {
		return throw 'abstract';
	}
	function cleanup():Null<TweenCallback> {
		return null;
	}
	@:final public function update(amplitude:Float):Null<TweenCallback> {
		return 
			if (amplitude < 1e30)
				setValue(start + amplitude * delta);
			else 
				cleanup();
	}
}
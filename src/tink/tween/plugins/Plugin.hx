package tink.tween.plugins;

/**
 * ...
 * @author back2dos
 */
import tink.tween.Tween;

@:autoBuild(tink.tween.macros.PluginMap.register()) interface Plugin<T> {
	//function new(target:T, end:Float):Void;
	function update(amplitude:Float):Null<TweenCallback>;
}
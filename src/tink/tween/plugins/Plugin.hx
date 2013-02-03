package tink.tween.plugins;

import tink.tween.Tween;

@:autoBuild(tink.tween.macros.PluginMap.register()) interface Plugin<T> {
	//function new(target:T, end:Float):Void;
	function update(amplitude:Float):Null<TweenCallback>;
}
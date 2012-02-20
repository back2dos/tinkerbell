package tink.tween.plugins.macros;

/**
 * ...
 * @author back2dos
 */

@:autoBuild(tink.tween.plugins.macros.PluginMap.register()) interface Plugin<T> {
	//function new(target:T, end:Float):Void;
	function update(amplitude:Float):Void;
}
package tink.tween.plugins.macros;

/**
 * ...
 * @author back2dos
 */

@:autoBuild(tink.tween.plugins.macros.PluginMap.register()) class PluginBase<T> {
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
	function setValue(value:Float):Void {
		throw 'abstract';
	}
	function cleanup():Void {
		
	}
	@:final public function update(amplitude:Float):Void {
		if (amplitude < 1e30)
			setValue(start + amplitude * delta);
		else cleanup();
	}
}
package tink.lang.binding;

/**
 * ...
 * @author back2dos
 */

class Signaller {
	var propMap:Hash<Array<Void->Void>>;
	public function new() {
		this.propMap = new Hash();
	}
	public function bind(property:String) {
		//var b = Binding.getActive();
		//trace('watch ' + property + ' for ' + untyped Binding.stack.first());
		watch(property, Binding.getWatcher());
	}
	function watch(property:String, handler:Null<Void->Void>) {
		if (handler == null) return;
		var stack = propMap.get(property);
		if (stack == null)
			propMap.set(property, stack = []);
		stack.push(handler);	
	}
	public function fire(property:String) {
		if (propMap.exists(property)) {
			for (h in propMap.get(property)) h();
			propMap.set(property, []);
		}
	}
}
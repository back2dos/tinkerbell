package tink.reactive.signals;
import tink.collections.maps.FunctionMap;

/**
 * ...
 * @author back2dos
 */

interface Signal<T> {
	function on(handler:T->Dynamic):Void;
	function un(handler:T->Dynamic):Void;
}

class SimpleSignal<T> implements Signal<T> {
	var handlers:FunctionMap<T->Dynamic, T->Dynamic>;
	public function new() {
		this.handlers = new FunctionMap();
	}
	public function on(handler) {
		handlers.set(handler, handler);
	}
	public function un(handler) {
		handlers.remove(handler);
	}
	public function fire(data:T) {
		for (h in handlers.keys()) h(data);
	}
}
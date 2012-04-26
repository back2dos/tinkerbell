package tink.reactive.signals;
import tink.collections.maps.FunctionMap;

/**
 * ...
 * @author back2dos
 */

interface Signal<T> {
	function watch(handler:T->Dynamic):Void;
	function unwatch(handler:T->Dynamic):Void;
}

class SimpleSignal<T> implements Signal<T> {
	var handlers:FunctionMap<T->Dynamic, T->Dynamic>;
	public function new() {
		this.handlers = new FunctionMap();
	}
	public function watch(handler) {
		handlers.set(handler, handler);
	}
	public function unwatch(handler) {
		handlers.remove(handler);
	}
	public function fire(data:T) {
		for (h in handlers.keys()) h(data);
	}
}
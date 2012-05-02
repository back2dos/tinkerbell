package tink.collections.queues;
import tink.collections.maps.Map;

/**
 * ...
 * @author back2dos
 */

class UniqueQueue<T> implements Queue<T> {
	var actual:Queue<T>;
	var marker:Map<T, T>;
	public function new(?actual, marker) {
		this.actual = actual != null ? actual : new ArrayQueue();
		this.marker = marker;
	}
	public function add(item:T):Void {
		if (!marker.exists(item)) {
			marker.set(item, item);
			actual.add(item);
		}
	}
	public function isEmpty():Bool {
		return actual.isEmpty();
	}
	public function get():T {
		var ret = actual.get();
		marker.remove(ret);
		return ret;
	}
}
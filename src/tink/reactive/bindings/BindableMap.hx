package tink.reactive.bindings;

import tink.collections.maps.Map;
import tink.lang.Cls;

/**
 * ...
 * @author back2dos
 */
private class Entry<V> {
	public var value(get_value, set_value):V;
	var get_value:Void->V;
	var set_value:V->V;
	public function new(get_value, set_value) {
		this.get_value = get_value;
		this.set_value = set_value;
	}
}
class BindableMap<K, V> implements Map<K, V>, implements Cls {
	var map:Map<K, V>;
	public function new(?map) {
		this.map = 
			if (map == null) cast new tink.collections.maps.AnyMap<V>();
			else map;
	}
	public function entry(k:K): { var value(get_value, set_value):V; } {
		return new Entry(callback(get, k), callback(set, k));
	}
	@:bindable(change) public function get(k:K):Null<V> {
		return map.get(k);
	}
	public function set(k:K, v:V):V {
		this.map.set(k, v);
		this.bindings.fire('change');
		return v;
	}
	@:bindable(change) public function exists(k:K):Bool {
		return this.map.exists(k);
	}
	public function remove(k:K):Bool {
		return
			if (map.remove(k)) {
				this.bindings.fire('change');
				true;
			}
			else false;
	}
	@:bindable(change) public function keys():Iterator<K> {
		return map.keys();
	}
	@:bindable(change) public function iterator():Iterator<V> {
		return map.iterator();		
	}
}
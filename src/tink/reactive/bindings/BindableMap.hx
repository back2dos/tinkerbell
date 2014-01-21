package tink.reactive.bindings;

import tink.lang.Cls;

private class Entry<V> {
	public var value(get_value, set_value):V;
	var get_value:Void->V;
	var set_value:V->V;
	public var hasValue(default, null):Void->Bool;
	public function new(has, get_value, set_value) {
		this.get_value = get_value;
		this.set_value = set_value;
		this.hasValue = has;
	}
}
class BindableMap<K, V> implements Cls {
	//TODO: measure speedup gained by @:generic
	static inline var KEYS = 'KEYS';
	static inline var VALS = 'VALS';
	var map:Map<K, V>;
	public function new(?map) {
		this.map = 
			if (map == null) cast new tink.collections.maps.AnyMap<V>();
			else map;
	}
	public function entry(k:K): { var value(get_value, set_value):V; } {
		return new Entry(exists.bind(k), get.bind(k), set.bind(k));
	}
	@:bindable(k) public function get(k:K):Null<V> {
		return map.get(k);
	}
	public function set(k:K, v:V):V {
		var exists = map.exists(k);
		this.map.set(k, v);
		if (exists) 
			this.bindings.byUnknown.fire(k);
		else
			this.bindings.byString.fire(KEYS);
		this.bindings.byString.fire(VALS);
		return v;
	}
	@:bindable(k) public function exists(k:K):Bool {
		return this.map.exists(k);
	}
	public function remove(k:K):Bool {
		return
			if (map.remove(k)) {
				this.bindings.byString.fire(KEYS);
				this.bindings.byString.fire(VALS);
				true;
			}
			else false;
	}
	@:bindable(KEYS) public function keys():Iterator<K> {
		return map.keys();
	}
	@:bindable(VALS) public function iterator():Iterator<V> {
		return map.iterator();		
	}
}
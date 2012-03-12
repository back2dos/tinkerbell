package tink.reactive.bindings;

import tink.collections.Map;
import tink.lang.Cls;

/**
 * ...
 * @author back2dos
 */

class BindableMap<K, V> implements Map<K, V>, implements Cls {
	var map:Map<K, V>;
	public function new(?map) {
		this.map = 
			if (map == null) cast new tink.collections.AnyMap<V>();
			else map;
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
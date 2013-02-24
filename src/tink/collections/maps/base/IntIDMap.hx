package tink.collections.maps.base;

class IntIDMap<K, V> implements tink.collections.maps.Map<K, V> {
	var keyMap:Map<Int,K>;
	var valMap:Map<Int,V>;
	public function new() {
		this.keyMap = new Map();
		this.valMap = new Map();
	}
	function transform(key:K):Int {
		return throw "base";
	}
	public inline function get(key:K):Null<V> {
		return valMap.get(transform(key));
	}
	public function set(key:K, val:V):V {
		var k = transform(key);
		keyMap.set(k, key);
		valMap.set(k, val);
		return val;
	}
	public inline function exists(key:K):Bool {
		return keyMap.exists(transform(key));
	}
	public inline function keys():Iterator<K> {
		return keyMap.iterator();		
	}
	public inline function iterator():Iterator<V> {
		return valMap.iterator();
	}
	public function remove(key:K):Bool {
		var k = transform(key);
		return keyMap.remove(k) && valMap.remove(k);
	}
}
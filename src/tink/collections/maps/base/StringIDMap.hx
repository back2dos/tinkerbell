package tink.collections.maps.base;

class StringIDMap<K, V> implements tink.collections.maps.Map<K, V> {
	var keyMap:Hash<K>;
	var valMap:Hash<V>;
	public function new() {
		this.keyMap = new Hash();
		this.valMap = new Hash();
	}
	function transform(key:K):String {
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
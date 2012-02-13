package tink.collections.abstract;

/**
 * ...
 * @author back2dos
 */

class IntIDMap<K, V> {
	var keyMap:IntHash<K>;
	var valMap:IntHash<V>;
	public function new() {
		this.keyMap = new IntHash();
		this.valMap = new IntHash();
	}
	function transform(key:K):Int {
		return throw "abstract";
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
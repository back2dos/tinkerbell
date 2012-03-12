package tink.collections.maps.abstract;

/**
* ...
* @author back2dos
*/

class KVPairMap < K, V > implements Map < K, V > {
	var keyList:Array<K>;
	var valList:Array<V>;
	public function new() {
		this.keyList = [];
		this.valList = [];
	}
	function equals(k1:K, k2:K):Bool {
		return throw 'abstract';
	}
	function indexOf(k:K):Int {
		for (i in 0...keyList.length)
			if (equals(k, keyList[i])) return i;
		return -1;
	}
	public function get(k:K):Null<V> {
		return valList[indexOf(k)];
	}
	public function set(k:K, v:V):V {
		var i = indexOf(k);
		if (i == -1) {
			keyList.push(k);
			valList.push(v);
		}
		else {
			keyList[i] = k;
			valList[i] = v;
		}
		return v;
	}
	public function exists(k:K):Bool {
		return indexOf(k) != -1;
	}
	public function remove(k:K):Bool {
		var i = indexOf(k);
		return
			if (i == -1) false;
			else {
				keyList.splice(i, 1);
				valList.splice(i, 1);
				true;
			}
	}
	public inline function keys():Iterator<K> {
		return keyList.iterator();
	}
	public inline function iterator():Iterator<V> {
		return valList.iterator();
	}
}
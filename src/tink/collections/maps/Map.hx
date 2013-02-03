package tink.collections.maps;

interface Map<K, V> {
	function get(k:K):Null<V>;
	function set(k:K, v:V):V;
	function exists(k:K):Bool;
	function remove(k:K):Bool;
	function keys():Iterator<K>;
	function iterator():Iterator<V>;
}
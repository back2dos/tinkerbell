package tink.collections.sets;

interface Set<T> {
	function iterator():Iterator<T>;
	function add(e:T):Bool;
	function remove(e:T):Bool;
	function contains(e:T):Bool;
}
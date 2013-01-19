package tink.collections.queues;

interface Queue<T> {
	function add(item:T):Void;
	function isEmpty():Bool;
	function get():T;
}
package tink.collections.queues;

/**
 * ...
 * @author back2dos
 */

interface Queue<T> {
	function add(item:T):Void;
	function isEmpty():Bool;
	function get():T;
}
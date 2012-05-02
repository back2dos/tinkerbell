package tink.collections.queues;
import tink.lang.Cls;

/**
 * ...
 * @author back2dos
 */

class ArrayQueue<T> implements Queue<T> {
	var entries:Array<T>;
	var zero:Int;
	public var count(default, null):Int;
	public function new(?length = 64) {
		entries = forLength(length);
		zero = count = 0;
	}
	public function add(item:T):Void {
		if (count == entries.length) {
			entries = entries.slice(zero, count).concat(entries.slice(0, count)).concat(forLength(count));
			zero = 0;
			add(item);
		}
		else {
			entries[(zero + count++) % entries.length] = item;
		}
	}
	public inline function isEmpty():Bool {
		return count == 0;
	}
	public function get():T {
		if (isEmpty()) throw 'queue is empty';
		else {
			var ret = entries[zero];
			zero = (zero + 1) % entries.length;
			count--;
			return ret;
		}
	}
	static var cache = [[null]];
	static function getArray(p2) {
		for (i in cache.length...p2+1)
			cache.push(cache[i - 1].concat(cache[i - 1]));
		return cache[p2];
	}
	static function forLength(l) {
		return 
			if (l < 1) 
				getArray(0);
			else 
				getArray(Math.floor(Math.log(l) / Math.log(2)));
	}
}
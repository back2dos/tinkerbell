package tink.collections;
import tink.lang.Cls;

/**
 * ...
 * @author back2dos
 */

class StringMap<T> implements Map < String, T >, implements Cls {
	@:forward var h:Hash<T>;
	public function new() {
		this.h = new Hash();
	}
	public inline function set(key:String, value:T) {
		h.set(key, value);
		return value;
	}
}
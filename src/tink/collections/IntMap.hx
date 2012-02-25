package tink.collections;
import tink.lang.Cls;

/**
 * ...
 * @author back2dos
 */

class IntMap<T> implements Cls, implements Map < Int, T > {
	@:forward var h:IntHash<T>;
	public function new() {
		this.h = new IntHash();
	}
	public inline function set(key:Int, value:T):T {
		h.set(key, value);
		return value;
	}
	
}
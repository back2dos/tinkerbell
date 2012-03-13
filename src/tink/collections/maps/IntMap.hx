package tink.collections.maps;
import tink.lang.Cls;

/**
 * ...
 * @author back2dos
 */

#if macro
	class IntMap<T> extends tink.collections.maps.abstract.IntIDMap<Int, T> {
		override function transform(k:Int) {
			return k;
		}
	}
#else
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
#end
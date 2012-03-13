package tink.collections.maps;
import tink.lang.Cls;

/**
 * ...
 * @author back2dos
 */
#if macro
	class StringMap<T> extends tink.collections.maps.abstract.StringIDMap<String, T> {
		override function transform(k:String) {
			return k;
		}
	}
#else
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
#end
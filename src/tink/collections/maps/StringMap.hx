package tink.collections.maps;
import tink.lang.Cls;

/**
 * ...
 * @author back2dos
 */
#if macro
	class StringMap<T> extends tink.collections.maps.base.StringIDMap<String, T> {
		override function transform(k:String) {
			return k;
		}
	}
#else
	class StringMap<T> implements Map < String, T > implements Cls {
		@:forward var h:Map<StringT>;
		public function new() {
			this.h = new Map();
		}
		public inline function set(key:String, value:T) {
			h.set(key, value);
			return value;
		}
	}
#end
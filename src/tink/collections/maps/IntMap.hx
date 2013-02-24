package tink.collections.maps;

import tink.lang.Cls;

#if macro
	class IntMap<T> extends tink.collections.maps.base.IntIDMap<Int, T> {
		override function transform(k:Int) {
			return k;
		}
	}
#else
	class IntMap<T> implements Cls implements Map < Int, T > {
		@:forward var h:Map<Int,T>;
		public function new() {
			this.h = new Map();
		}
		public inline function set(key:Int, value:T):T {
			h.set(key, value);
			return value;
		}	
	}
#end
package tink.collections.maps;

#if flash9
	import flash.utils.Dictionary;
	class ObjectMap < K, V > extends Dictionary implements Map < K, V > {
		public function new() {
			super(false);
		}
		public inline function get(k:K):Null<V> {
			return untyped this[k];
		}
		public inline function set(k:K, v:V):V {
			return untyped this[k] = v;
		}
		public inline function exists(k:K):Bool {
			return untyped this[k] != null;
		}
		public inline function remove(k:K):Bool {
			return untyped __delete__(this,k);
		}
		public inline function keys():Iterator<K> {
			var ret:Array<K> = untyped __keys__(this);
			return ret.iterator();
		}
		public function iterator():Iterator<V> {
			var k = this.keys();
			return {
				hasNext: function () return k.hasNext(),
				next: function () return this.get(k.next())
			}
		}
	}
#elseif php
	import tink.native.PHP;
	class ObjectMap < K, V > extends tink.collections.maps.base.StringIDMap < K, V > {
		override function transform(key:K):String untyped {
			return PHP.objMap(key);
		}
	}
#elseif (flash || js || neko || cpp)
	class ObjectMap < K, V > extends tink.collections.maps.base.IntIDMap < K, V > {
		#if !cpp
			static var idCounter = 0;
		#end
		override function transform(key:K):Int untyped {			
			#if cpp
				return untyped __global__.__hxcpp_obj_id (key);
			#else
				var id = key.__getID;
				if (id == null) {
					var v = idCounter++;
					key.__getID = id = function () return v;
				}
				return id();
			#end
		}
	}
#else
	#error
#end
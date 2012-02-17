package tink.collections;


/**
 * ...
 * @author back2dos
 */

#if flash9
	import flash.utils.Dictionary;
	class ObjectMap < K, V > extends Dictionary, implements Map < K, V > {
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
	class ObjectMap < K, V > extends tink.collections.abstract.StringIDMap < K, V > {
		override function transform(key:K):String untyped {
			return PHP.objHash(key);
		}
	}
#else
	class ObjectMap < K, V > extends tink.collections.abstract.IntIDMap < K, V > {
		#if (flash || js)
			static var idCounter = 0;
		#end
		override function transform(key:K):Int untyped {			
			#if neko
				return $iadd(key, 0);//this is pure evil, but it seems to work perfectly
			#elseif (flash || js)
				var id = key.__getID;
				if (id == null) {
					var v = idCounter++;
					key.__getID = id = function () return v;
				}
				return id();
			#elseif cpp
				return untyped __global__.__hxcpp_obj_id (key);
			#else
				#error
			#end
		}
	}
#end
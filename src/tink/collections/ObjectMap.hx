package tink.collections;


/**
 * ...
 * @author back2dos
 */

#if flash9
	import flash.utils.Dictionary;
	class ObjectMap<K,V> extends Dictionary {
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
			if (PHP.embed('is_array($key)')) {
				if (PHP.embed('is_callable($key)')) 
					return transform(key[0]) + key[1];
				else 
					throw 'cannot handle native PHP arrays yet';
			}
			else return PHP.embed('spl_object_hash($key)');
		}
	}
#else
	class ObjectMap < K, V > extends tink.collections.abstract.IntIDMap < K, V > {
		#if (flash || js)
			static var idCounter = 0;
		#end
		override function transform(key:K):Int untyped {			
			#if neko
				return $iadd(key, 0);
			#elseif (flash || js)
				var id = key.__id__;
				if (id == null) {
					var v = idCounter++;
					key.__id__ = id = function () return v;
				}
				return id();
			#elseif cpp
				#error
			#else
				#error
			#end
		}
	}
#end
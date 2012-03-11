package tink.collections.maps;


/**
 * ...
 * @author back2dos
 */

#if macro
	class FunctionMap < K, V > implements Map < K, V > {
		var keyList:Array<K>;
		var valList:Array<V>;
		public function new() {
			this.keyList = [];
			this.valList = [];
		}
		function indexOf(k:K):Int {
			for (i in 0...keyList.length)
				if (Reflect.compareMethods(k, key)) return i;
			return -1;
		}
		public function get(k:K):Null<V> {
			return valList[indexOf(k)];
		}
		public function set(k:K, v:V):V {
			var i = indexOf(k);
			if (i == -1) {
				keyList.push(k);
				valList.push(v);
			}
			else {
				keyList[i] = k;
				valList[i] = v;
			}
			return v;
		}
		public function exists(k:K):Bool {
			for (key in keyList)
				if (Reflect.compareMethods(k, key)) return true;
			return false;
		}
		public function remove(k:K):Bool {
			var i = indexOf(k);
			return
				if (i == -1) false;
				else {
					keyList.splice(i, 1);
					valList.splice(i, 1);
					true;
				}
		}
		public inline function keys():Iterator<K> {
			return keyList.iterator();
		}
		public inline function iterator():Iterator<V> {
			return valList.iterator();
		}
	}
#elseif neko
	class FunctionMap < K, V > extends tink.collections.maps.abstract.IntIDMap < K, V > {
		override function transform(k:K) {
			return untyped $iadd(k, 0);//this is really evil, but it seems to work perfectly!
		}
	}
#else
	class FunctionMap < K, V > extends ObjectMap < K, V > { }
#end
package tink.collections.maps;

#if flash9
	abstract FunctionMap<K, V>(ObjectMap<Dynamic, V>) { 
		public inline function new() this = new ObjectMap();
		public inline function get(k:K):Null<V> return this.get(k);
		public inline function set(k:K, v:V):Void this.set(k, v);
		public inline function exists(k:K):Bool return this.exists(k);
		public inline function remove(k:K):Bool return this.remove(k);
		public inline function keys():Iterator<K> return this.keys();
		public inline function iterator():Iterator<V> return this.iterator();
		public inline function toString():String return this.toString();
		
		@:to public inline function toMap():Map<K, V> return this;
		@:to public inline function toIterable():Iterable<V> return this;
	}
#elseif (flash || js)
	class FunctionMap < K, V > extends tink.collections.maps.base.StringIDMap < K, V > { 
		static var idCounter = 0;
		function objID(o:Dynamic):String untyped {			
			var id = o.__getID;
			if (id == null) {
				var v = Std.string(idCounter++);
				o.__getID = id = function () return v;
			}
			return id();		
		}
		override function transform(k:K):String untyped {
			return
				#if js
					if (k == null) 'null';
					else if (k.scope) objID(k.scope) + k.method;
					else objID(k);
				#else
					if (k == null) 'null';
					else if (k.o) objID(k.o) + k.f;
					else objID(k);					
				#end
		}
	}	
#else
	//TODO: optimize for both neko and c++ - depends on the ability do decompose a method closure to it's components or have another way to get a unique ID for method closures
	class FunctionMap < K, V > extends tink.collections.maps.base.KVPairMap < K, V > {
		override function equals(k1:K, k2:K):Bool {
			return Reflect.compareMethods(k1, k2);
		}
	}
#end
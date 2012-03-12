package tink.collections.maps;

/**
 * ...
 * @author back2dos
 */

#if macro
	class FunctionMap < K, V > extends tink.collections.maps.abstract.KVPairMap < K, V > {
		
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
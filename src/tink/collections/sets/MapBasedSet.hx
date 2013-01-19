package tink.collections.sets;

import tink.collections.maps.Map;
import tink.collections.maps.AnyMap;

class MapBasedSet<T> implements Set<T> {
	var map:Map<T, T>;
	public function new(?over) 
		map =
			if (over == null) cast new AnyMap()
			else over
	
	public inline function iterator():Iterator<T> 
		return map.iterator()
	
	public inline function add(e:T):Bool 
		return 
			if (map.exists(e)) false
			else {
				map.set(e, e);
				true;
			}
	
	public inline function remove(e:T)
		return map.remove(e)
	
	public inline function contains(e:T)
		return map.exists(e)
	
	
}
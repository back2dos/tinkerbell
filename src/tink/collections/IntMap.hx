package tink.collections;

/**
 * ...
 * @author back2dos
 */

class IntMap<T> extends tink.collections.abstract.IntIDMap<Int, T> {
	override function transform(k:Int) {
		return k;
	}
	
}
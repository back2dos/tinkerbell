package tink.collections;

/**
 * ...
 * @author back2dos
 */

class StringMap<T> extends tink.collections.abstract.StringIDMap<String, T> {
	override function transform(k:String) {
		return k;
	}
}
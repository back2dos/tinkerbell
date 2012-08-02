package tink.collections.maps;

/**
 * ...
 * @author back2dos
 */

class BoolMap<V> implements Map<Bool, V> {
	var hasTrue:Bool;
	var hasFalse:Bool;
	var trueVal:Null<V>;
	var falseVal:Null<V>;
	public function new() {
		hasTrue = hasFalse = false;//for dynamic platforms
	}
	public inline function get(k:Bool):Null<V> {
		return k ? trueVal : falseVal;
	}
	public inline function set(k:Bool, v:V):V {
		if (k) {
			hasTrue = true;
			trueVal = v;
		}
		else {
			hasFalse = true;
			falseVal = v;
		}
		return v;
	}
	public inline function exists(k:Bool):Bool {
		return k ? hasTrue : hasFalse;
	}
	public function remove(k:Bool):Bool {
		return
			if (k) 
				if (hasTrue) {
					trueVal = null;
					hasTrue = false;
					true;
				}
				else false;
			else 
				if (hasFalse) {
					falseVal = null;
					hasFalse = false;
					false;
				}
				else true;
	}
	public inline function keys():Iterator<Bool> {
		var ret = [];
		if (hasTrue) ret.push(true);
		if (hasFalse) ret.push(false);
		return ret.iterator();
	}
	public inline function iterator():Iterator<V> {		
		var ret = [];
		if (hasTrue) ret.push(trueVal);
		if (hasFalse) ret.push(falseVal);
		return ret.iterator();
	}
}
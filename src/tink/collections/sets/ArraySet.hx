package tink.collections.sets;

import tink.lang.Cls;

class ArraySet<T> implements Set<T>, implements Cls {
	@:forward(iterator, length) inline var a:Array<T> = [];
	public function new() {}
		
	public function add(e:T):Bool {
		return
			if (contains(e)) false;
			else {
				true;
				a.push(e) > 0;//RAPTORS: while this saves returning true in a second statement (which is bad for javascript output), it's not exactly pretty
			}
	}
	public function remove(e:T) {
		for (i in 0...a.length)
			if (a[i] == e) {
				if (i < a.length - 1)
					a[i] = a.pop();
				else
					a.pop();
				return true;
			}
		return false;		
	}
	public function contains(e:T):Bool {
		for (x in a)
			if (x == e) 
				return true;
		return false;
	}
	#if js
		static function __init__() tink.native.JS.patchBind()
	#end
}
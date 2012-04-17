package tink.ui.core;

/**
 * ...
 * @author back2dos
 */

interface Pair<T> {
	function get(h:Bool):T;
}

class PlainPair<T> implements Pair<T> {
	var h:T;
	var v:T;
	public function new(h, v) {
		this.h = h;
		this.v = v;
	}	
	public function get(h:Bool):T {
		return h ? this.h : this.v;
	}
	public function set(h:Bool, value:T):T {
		if (h) this.h = value;
		else this.v = value;
		return value;
	}
}
import tink.reactive.bindings.Binding;
class BindingPair<T> implements Pair<T> {
	var h:Watch<T>;
	var v:Watch<T>;
	public function new(get_h, get_v) {
		this.h = new Watch(get_h);
		this.v = new Watch(get_v);
	}
	public function get(h:Bool):T {
		return h ? this.h.value : this.v.value;
	}
}
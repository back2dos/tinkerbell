package tink.reactive.bindings;

import tink.lang.Cls;
import tink.reactive.Source;

/**
 * ...
 * @author back2dos
 */
class Watch<T> extends Binding<T>, implements Source<T> {
	public var value(get_value, null):T;
	public function new(get) {
		super(get);
	}
}
class Link<T> extends Binding<T>, implements Editable<T> {
	public var value(get_value, set_value):T;
	var set:T->T;
	public function new(get, set) {
		this.set = set;
		super(get);
	}
	function set_value(v:T) {
		var ret = set(v);
		invalidate();
		return ret;
	}
}
class Binding<T> implements Cls {
	public var valid(default, null):Bool;
	static var stack = new List<Binding<Dynamic>>();
	var calc:Void->T;
	var cache:T;
	var busy:Bool;
	var id:Int = counter++;
	static var counter = 0;
	function new(calc) {
		this.calc = calc;
	}
	public function unwatch(handler:Void->Void):Void {}
	public function watch(handler:Void->Void):Void {}	
	function invalidate() {
		if (valid) {//invalid bindings don't need to fire really
			valid = false;
			this.bindings.fire('value');
		}
	}
	function doCalc() {
		if (busy) 
			throw 'cyclic binding occured';
		stack.push(this);
		busy = true;
		cache = calc();
		busy = false;
		valid = true;
		stack.pop();
		return cache;
	}
	function toString() {
		return '[Binding #' + id + ']';
	}
	@:bindable(value) function get_value():T {
		return
			if (valid) cache;
			else 
				doCalc();
	}
	static public inline function getWatcher() {
		return 
			if (stack.isEmpty()) null;
			else 
				stack.first().invalidate;
	}
}

class Signaller {
	var propMap:Hash<Array<Void->Void>>;
	public function new() {
		this.propMap = new Hash();
	}
	public function bind(property:String) {
		watch(property, Binding.getWatcher());
	}
	function watch(property:String, handler:Null<Void->Void>) {
		if (handler == null) return;
		var stack = propMap.get(property);
		if (stack == null)
			propMap.set(property, stack = []);
		stack.push(handler);	
	}
	public function fire(property:String) {
		if (propMap.exists(property)) {
			for (h in propMap.get(property)) h();
			propMap.set(property, []);
		}
	}
}
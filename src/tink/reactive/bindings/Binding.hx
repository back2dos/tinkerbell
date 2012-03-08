package tink.reactive.bindings;

import tink.lang.Cls;

/**
 * ...
 * @author back2dos
 */

class Binding<T> implements Cls {
	public var valid(default, null):Bool;
	static var stack = new List<Binding<Dynamic>>();
	var calc:Void->T;
	var cache:T;
	var busy:Bool;
	var id:Int = counter++;
	static var counter = 0;
	public function new(calc) {
		this.calc = calc;
	}
	function invalidate() {
		if (valid) {//invalid bindings don't need to fire really
			valid = false;
			this.bindings.fire('getValue');
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
	@:bindable public function getValue():T {
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
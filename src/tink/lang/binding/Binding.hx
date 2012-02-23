package tink.lang.binding;
import tink.lang.Cls;

/**
 * ...
 * @author back2dos
 */

class Binding<T> implements Cls {
	static var stack = new List<Binding<Dynamic>>();
	var calc:Void->T;
	var cache:T;
	public var valid(default, null):Bool;
	var busy:Bool;
	var id:Int = counter++;
	static var counter = 0;
	public function new(calc) {
		this.calc = calc;
	}
	public function invalidate() {
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
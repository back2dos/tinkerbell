package tink.util;

/**
 * ...
 * @author back2dos
 */

class Ints {
	static public inline function clamp(x:Int, min:Int, max:Int) {
		return 
			if (x > max) max;
			else if (x < min) min;
			else x;
	}
	static public inline function min(a:Int, b:Int) {
		return (a > b) ? b : a;
	}
	static public inline function max(a:Int, b:Int) {
		return (a < b) ? b : a;
	}
	static public inline function add(a:Int, b:Int) {
		return a + b;
	}
	static public inline function plus(c:Class<Int>) {
		return add;
	}
}
class Floats {
	static public inline function clamp(x:Float, min:Float, max:Float) {
		return 
			if (x > max) max;
			else if (x < min) min;
			else x;
	}
	static public inline function min(a:Float, b:Float) {
		return (a > b) ? b : a;
	}
	static public inline function max(a:Float, b:Float) {
		return (a < b) ? b : a;
	}
	static public inline function add(a:Float, b:Float) {
		return a + b;
	}
	static public inline function plus(c:Class<Float>) {
		return add;
	}
}
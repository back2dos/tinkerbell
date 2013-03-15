package lang;

import haxe.unit.TestCase;
import tink.lang.Cls;
using Lambda;
/**
 * ...
 * @author back2dos
 */

class ClsTest extends TestCase {

	public function new() {
		super();
	}
	function testFwdBuild() {
		var last = null;
		function add(a, b) {
			last = 'add';
			return a + b;
		}
		function subtract(a, b) {
			last = 'subtract';
			return a - b;
		}
		var target = {
			add: add,
			subtract: subtract,
			multiply: subtract,
			x: 1,
		};
		var f = new Forwarder(target);
		assertTrue(Reflect.field(f, 'multiply') == null);
		assertTrue(Reflect.field(f, 'add') != null);
		
		assertEquals(f.foo1(1, 2, 3), 'foo1_3');
		assertEquals(f.bar1(1), 'bar1_1');
		assertEquals(f.foo2(true, true), 'foo2_2');
		assertEquals(f.bar2(), 'bar2_0');
		
		for (i in 0...10) {
			var a = Std.random(100),
				b = Std.random(100),
				x = Std.random(100);
				
			assertEquals(f.add(a, b), add(a, b));
			assertEquals(last, 'add');
			assertEquals(f.subtract(a, b), subtract(a, b));
			assertEquals(last, 'subtract');
			f.x = x;
			f.y = x;
			assertEquals(f.x, x);
			assertEquals(f.y, x);
			assertEquals(target.x, x);
		}		
	}
	function testPropertyBuild() {
		var b = new Built();
		assertEquals(0, b.a);
		assertEquals(1, b.b);
		assertEquals(2, b.c);
		assertEquals(3, b.d);
		assertEquals(4, b.e);
		assertEquals(5, b.f);
		                
		assertEquals(6, b.g);
		b.g = 3;        
		assertEquals(6, b.g);
		                
		assertEquals(7, b.h);
		b.h = 7;        
		assertEquals(7, b.h);
		                
		assertEquals(8, b.i);
		b.i = 8;
		#if !cpp //in cpp this will fail, since Reflect.field calls the accessor
			assertFalse(Reflect.field(b, 'i') == b.i);
		#end
		assertEquals(b.i, 8);
		for (i in 0...10) {
			b.i = Std.random(100);
			assertEquals(b.h+1, b.i);
		}
	}
	function compareFloatArray(expected:Array<Float>, found:Array<Float>) {
		assertEquals(expected.length, found.length);
		for (i in 0...expected.length) 
			assertTrue(Math.abs(expected[i] - found[i]) < .0000001);
	}
	function compareArray<A>(expected:Array<A>, found:Array<A>) {
		assertEquals(expected.length, found.length);
		for (i in 0...expected.length) 
			assertEquals(expected[i], found[i]);
	}
	function testForLoops() {
		var loop = new SuperLooper(),
			control = new ControlLooper();
		
		function floatUp(start, end, step, ?breaker) {
			if (breaker == null) breaker = function (_) return false;
			compareFloatArray(
				loop.floatUp(start, end, step, breaker),
				control.floatUp(start, end, step, breaker)
			);
		}
		function floatDown(end, start, step, ?breaker) {
			if (breaker == null) breaker = function (_) return false;
			compareFloatArray(
				loop.floatDown(start, end, step, breaker),
				control.floatDown(start, end, step, breaker)
			);
		}
		function intUp(start, end, step, ?breaker) {
			if (breaker == null) breaker = function (_) return false;
			compareArray(
				loop.intUp(start, end, step, breaker),
				control.intUp(start, end, step, breaker)
			);
		}
		function intDown(end, start, step, ?breaker) {
			if (breaker == null) breaker = function (_) return false;
			compareArray(
				loop.intDown(start, end, step, breaker),
				control.intDown(start, end, step, breaker)
			);
		}	
		
		compareFloatArray(
			control.floatUp(0.1, 2.9, 0.5, function (_) return false),
			[0.1, 0.6, 1.1, 1.6, 2.1, 2.6]
		);
		compareArray(
			control.intUp(3, 17, 4, function (_) return false),
			[3, 7, 11, 15]
		);
		
		compareFloatArray(
			control.floatUp(0, 10, .3, function (_) return false),
			{
				var a = control.floatDown(10, 0, .3, function (_) return false);
				a.reverse();
				a;
			}
		);
		
		compareArray(
			control.intUp(0, 100, 3, function (_) return false),
			{
				var a = control.intDown(100, 0, 3, function (_) return false);
				a.reverse();
				a;
			}
		);
		for (i in 0...50) {
			floatUp(0, i, .1);
			floatUp(0, 0.1 * i, .1);
			var breakAt = (i >>> 1) + Std.random(i);
			floatUp(0, i, 1.0, function (i) return i >= breakAt);
			intUp(0, i, 3);
			intUp(0, 3 * i, 3);
			var breakAt = (i >>> 1) + Std.random(i);
			intUp(0, i, 1, function (i) return i >= breakAt);
			floatDown(0, i, .1);
			floatDown(0, 0.1 * i, .1);
			var breakAt = (i >>> 1) + Std.random(i);
			floatDown(0, i, 1.0, function (i) return i >= breakAt);
			intDown(0, i, 3);
			intDown(0, 3 * i, 3);
			var breakAt = (i >>> 1) + Std.random(i);
			intDown(0, i, 1, function (i) return i >= breakAt);
		}
	}
	function testSuperConstructor() {
		var c = new Child("1", 2);
		assertEquals("1", c.a);
		assertEquals(2, c.b);
		assertEquals(3, c.c);
		assertEquals(2, c.d);
		assertEquals("1", c.e);

		var c2 = new Child("1", 2, 9);
		assertEquals("1", c2.a);
		assertEquals(2, c2.b);
		assertEquals(9, c2.c);
		assertEquals(2, c2.d);
		assertEquals("1", c2.e);

		var c3 = new Child2("1", 2);
		assertEquals("1", c3.a);
		assertEquals(2, c3.b);
		assertEquals(3, c3.c);
		assertEquals(2, c3.d);
		assertEquals("1", c3.e);		
	}
}
typedef FwdTarget = {
	function add(a:Int, b:Int):Int;
	function subtract(a:Int, b:Int):Int;
	function multiply(a:Int, b:Int):Int;
	var x:Int;
}
typedef Fwd1 = {
	var y:Float;
	function foo1(a:Int, b:Int, c:Int):Void;
	function bar1(x:Float):Void;
}
typedef Fwd2 = {
	function foo2(f:Bool, g:Bool):Void;
	function bar2():Void;
}
class Forwarder implements Cls {
	var fields:Hash<Dynamic> = new Hash<Dynamic>();
	@:forward(!multiply) var target:FwdTarget;
	@:forward function fwd2(x:Fwd2, x:Fwd1) {
		get: fields.get($name),
		set: fields.set($name, param),
		call: $name + '_' + $args.length
	}
	public function new(target) {
		this.target = target;
	}
}
class Built implements Cls {
	public var a:Int = 0;
	@:read var b:Int = 1;
	@:read(2) var c:Int;
	@:read(3) var d:Int = 7;
	@:read(2 * e) var e:Int = 2;
	@:prop var f:Int = 5;
	@:prop(param << 1) var g:Int = 6;
	@:isVar @:prop(h >>> 1, h = param << 1) var h:Int = 14;
	@:prop(h+1, h = param-1) var i:Int;
	public function new() {}
}

class Base {
	public var a:String;
	public function new(a:String) {
		this.a = a;
	}
}

class Child extends Base implements Cls {
	public var b:Int = _;
	public var c = (3);
	public var d:Int = b;
	public var e:String = a;
}

class Child2 extends Child {

}
class ControlLooper {
	public function new() { }
	public function floatUp(start:Float, end:Float, step:Float, breaker) {
		var ret = [];
		for (i in 0...Math.ceil((end - start) / step)) {
			if (breaker(i)) break;
			ret.push(i * step + start);
		}
		return ret;
	}
	public function floatDown(start:Float, end:Float, step:Float, breaker) {
		var ret = [];
		var count = Math.ceil((start - end) / step);
		for (i in 0...count) {
			var i = count - i - 1;
			if (breaker(i)) break;
			ret.push(i * step + end);
		}
		return ret;
	}
	public function intUp(start:Int, end:Int, step:Int, breaker) {
		var ret = [];
		for (i in 0...Math.ceil((end - start) / step)) {
			if (breaker(i)) break;
			ret.push(i * step + start);
		}
		return ret;
	}
	public function intDown(start:Int, end:Int, step:Int, breaker) {
		var ret = [];
		var count = Math.ceil((start - end) / step);
		for (i in 0...count) {
			var i = count - i - 1;
			if (breaker(i)) break;
			ret.push(i * step + end);
		}
		return ret;
	}	
}
class SuperLooper implements Cls {
	public function new() { }
	public function floatUp(start:Float, end:Float, step:Float, breaker) {
		var ret = [];
		for (i += step in start...end) {
			if (breaker(i)) break;
			ret.push(i);
		}
		return ret;
	}
	public function floatDown(start:Float, end:Float, step:Float, breaker) {
		var ret = [];
		for (i -= step in start...end) {
			if (breaker(i)) break;
			ret.push(i);
		}
		return ret;		
	}
	public function intUp(start:Int, end:Int, step:Int, breaker) {
		var ret = [];
		for (i += step in start...end) {
			if (breaker(i)) break;
			ret.push(i);
		}
		return ret;
	}
	public function intDown(start:Int, end:Int, step:Int, breaker) {
		var ret = [];
		for (i -= step in start...end) {
			if (breaker(i)) break;
			ret.push(i);
		}
		return ret;		
	}	
}
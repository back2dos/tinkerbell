package lang;

import haxe.unit.TestCase;
import tink.lang.Cls;

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
		assertEquals(b.a, 0);
		assertEquals(b.b, 1);
		assertEquals(b.c, 2);
		assertEquals(b.d, 3);
		assertEquals(b.e, 4);
		assertEquals(b.f, 5);
		
		assertEquals(b.g, 6);
		b.g = 3;
		assertEquals(b.g, 6);
		
		assertEquals(b.h, 7);
		b.h = 7;
		assertEquals(b.h, 7);
		
		assertEquals(b.i, 8);
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
	@:prop(h >>> 1, h = param << 1) var h:Int = 14;
	@:prop(h+1, h = param-1) var i:Int;
	public function new() {}
}

class Base {
	public var a:String;
	public function new(a:String) {
		this.a = a;
	}
}

class Child extends Base, implements Cls {
	public var b:Int = _;
	public var c = (3);
	public var d:Int = b;
	public var e:String = a;
}

class Child2 extends Child {

}
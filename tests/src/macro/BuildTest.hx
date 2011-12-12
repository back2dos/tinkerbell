package macro;
import haxe.unit.TestCase;
import tink.TinkClass;

/**
 * ...
 * @author back2dos
 */

class BuildTest extends TestCase {

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
		for (i in 0...10) {
			var a = Std.random(100),
				b = Std.random(100),
				x = Std.random(100);
			assertEquals(f.add(a, b), add(a, b));
			assertEquals(last, 'add');
			assertEquals(f.subtract(a, b), subtract(a, b));
			assertEquals(last, 'subtract');
			f.x = x;
			assertEquals(f.x, x);
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
		assertFalse(Reflect.field(b, 'i') == b.i);
		assertEquals(b.i, 8);
		for (i in 0...10) {
			b.i = Std.random(100);
			assertEquals(b.h+1, b.i);
		}
	}
}
typedef FwdTarget = {
	function add(a:Int, b:Int):Int;
	function subtract(a:Int, b:Int):Int;
	function multiply(a:Int, b:Int):Int;
	var x:Int;
}
class Forwarder implements TinkClass {
	@:forward(!multiply) var target:FwdTarget;
	public function new(target) {
		this.target = target;
	}
}
class Built implements TinkClass {
	public var a:Int = 0;
	@:read var b:Int = 1;
	@:read(2) var c:Int;
	@:read(3) var d:Int = 7;
	@:read(2 * e) var e:Int = 2;
	@:prop var f:Int = 5;
	@:prop(param << 1) var g:Int = 3;
	@:prop(h >>> 1, h = param << 1) var h:Int = 7;
	@:prop(h+1, h = param-1) var i:Int;
	public function new() {
		
	}
}
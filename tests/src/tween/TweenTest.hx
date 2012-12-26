package tween;

import haxe.unit.TestCase;
import tink.tween.Tween;
import tink.tween.Tweener;

using tink.tween.Tweener;

class TweenTest extends TestCase {
	var _x:Float;
	public var x(get_x, set_x):Float;
	public var y:Float;
	function get_x() {
		return _x / 2;
	}
	function set_x(param:Float) {
		return _x = param * 2;
	}
	function linear(f:Float) {
		return f;
	}
	function testTween() {
		this.x = 1;
		this.y = 2;		
		var d1 = false,
			d2 = false;
		assertEquals(_x, 2);
		//this.tween(x = 5, y = 6, $duration = 2, $easing = linear, $onDone = (d1 = true));
		this.tween(x = 5, y = 6, $duration = 2, $easing = linear, $onDone = (d1 = true));
		Tweener.group.heartbeat(1);
		this.tween(y = 0, $duration = 1, $easing = linear, $onDone = (d2 = true));
		assertEquals(3.0, x);
		assertEquals(4.0, y);
		assertFalse(d1);
		assertFalse(d2);
		Tweener.group.heartbeat(1);
		assertEquals(5.0 - x, .0);//will fail on PHP otherwise. Go figure.
		assertEquals(0.0, y);
		assertTrue(d1);
		assertTrue(d2);
	}
}
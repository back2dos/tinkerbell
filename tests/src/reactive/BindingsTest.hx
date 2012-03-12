package reactive;

import haxe.unit.TestCase;
import tink.lang.Cls;
import tink.reactive.bindings.BindableArray;
import tink.reactive.bindings.BindableMap;
import tink.reactive.bindings.Binding;

/**
 * ...
 * @author back2dos
 */

class BindingsTest extends TestCase {
	function testBindings() {
		var bs = new BindableArray();
		for (i in 0...3)
			bs.push(new Bindable());
		var sum = new Watch(function () {
			var ret = 0;
			for (b in bs)
				ret += b.summand;
			return ret;
		});
		var product = new Watch(function () {
			var ret = 1;
			for (b in bs)
				ret *= b.factor;
			return ret;			
		});
		var difference = new Watch(function () return product.value - sum.value);
		
		assertFalse(sum.valid);
		assertFalse(product.valid);
		assertFalse(difference.valid);
		
		assertEquals(1, difference.value);
		assertEquals(0, sum.value);
		assertEquals(1, product.value);
		
		assertTrue(sum.valid);
		assertTrue(product.valid);
		assertTrue(difference.valid);
		
		bs.get(2).summand += 6;
		
		assertFalse(sum.valid);
		assertTrue(product.valid);
		assertFalse(difference.valid);
		
		assertEquals(6, sum.value);

		assertTrue(sum.valid);
		assertTrue(product.valid);
		assertFalse(difference.valid);
		
		bs.push(new Bindable(3, 3));
		
		assertFalse(sum.valid);
		assertFalse(product.valid);
		assertFalse(difference.valid);
		
		assertEquals(9, sum.value);
		assertEquals(3, product.value);
	}
	function testBindableMap() {
		var m = new tink.reactive.bindings.BindableMap();
		for (i in 0...10)
			m.set(i, i+1);
		assertEquals(10, Lambda.count(m));
		var b = new Watch(function () {
			var ret:Int = 0;
			for (k in m.keys()) 
				ret += m.get(k) + k;
			return ret;
		});
		assertEquals(100, b.value);
		m.set(20, 30);
		assertEquals(150, b.value);
		var bk = new Watch(function () return m.get(20));
		assertEquals(bk.value, 30);
		m.set(5, 7);
		assertTrue(bk.valid);
		m.set(20, 50);
		assertFalse(bk.valid);
	}
}


class Bindable implements Cls {
	@:bindable var summand:Int;
	@:bindable var factor:Int;
	public function new(?summand = 0, factor = 1) {
		this.summand = summand;
		this.factor = factor;
	}
}
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
		var sum = new Binding(function () {
			var ret = 0;
			for (b in bs)
				ret += b.summand;
			return ret;
		});
		var product = new Binding(function () {
			var ret = 1;
			for (b in bs)
				ret *= b.factor;
			return ret;			
		});
		var difference = new Binding(function () return product.getValue() - sum.getValue());
		
		assertFalse(sum.valid);
		assertFalse(product.valid);
		assertFalse(difference.valid);
		
		assertEquals(1, difference.getValue());
		assertEquals(0, sum.getValue());
		assertEquals(1, product.getValue());
		
		assertTrue(sum.valid);
		assertTrue(product.valid);
		assertTrue(difference.valid);
		
		bs.get(2).summand += 6;
		
		assertFalse(sum.valid);
		assertTrue(product.valid);
		assertFalse(difference.valid);
		
		assertEquals(6, sum.getValue());

		assertTrue(sum.valid);
		assertTrue(product.valid);
		assertFalse(difference.valid);
		
		bs.push(new Bindable(3, 3));
		
		assertFalse(sum.valid);
		assertFalse(product.valid);
		assertFalse(difference.valid);
		
		assertEquals(9, sum.getValue());
		assertEquals(3, product.getValue());
	}
	function testBindableMap() {
		var m = new tink.reactive.bindings.BindableMap();
		for (i in 0...10)
			m.set(i, i+1);
		//trace(m);
		assertEquals(10, Lambda.count(m));
		//trace(m);
		var b = new Binding(function () {
			var ret:Int = 0;
			for (k in m.keys()) {
				ret += m.get(k) + k;
			}
			return ret;
		});
		
		assertEquals(100, b.getValue());
		m.set(20, 30);
		assertEquals(150, b.getValue());
	}
}


class Bindable implements Cls {
	@:bindable @:prop var summand:Int;
	@:bindable var factor:Int;
	public function new(?summand = 0, factor = 1) {
		this.summand = summand;
		this.factor = factor;
	}
}
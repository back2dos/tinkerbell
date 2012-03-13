package collections;

import haxe.unit.TestCase;
import tink.collections.maps.FunctionMap;
import tink.collections.maps.ObjectMap;
import tink.collections.maps.AnyMap;

//My tendency to typos aside, it is practically impossible for these two not to work. So if they compile, I consider them covered.
import tink.collections.maps.IntMap;
import tink.collections.maps.StringMap;

using tink.collections.maps.MapTools;
/**
 * ...
 * @author back2dos
 */

class MapTest extends TestCase {
	function testObjectMap() {
		var o = new ObjectMap(),
			vals = [
				{ foo: 1 },
				{ foo: 2 },
			];
		for (v in vals)
			o.set(v, v);
		vals[0].foo = 123456;
		vals[1].foo = 654321;
		for (v in vals)
			assertEquals(v, o.get(v));
		assertEquals(Lambda.count(o), 2);
	}
	function testFunctionMap() {
		var o = new FunctionMap(),
			vals = [
				function () return 0,
				function () return 1,
				function () return 2
			];
		for (v in vals)
			o.set(v, v);			
		assertEquals(3, Lambda.count(o));
		o.set(foo, foo);
		o.set(foo, foo);
		assertEquals(4, Lambda.count(o));
	}
	function foo() {
		return 5;
	}
	function testAnyMap() {
		var a:Array<Dynamic> = [];
		a.push(5);
		a.push(4);
		a.push(true);
		a.push(false);
		a.push(null);
		a.push(Math.POSITIVE_INFINITY);
		a.push(Math.PI);
		a.push(Math.NaN);
		a.push(1 / 3);
		a.push('foo');
		a.push('bar');
		a.push(function () return 5);
		a.push(function () return 6);
		var m = new AnyMap();
		for (i in 0...a.length)
			m.set(a[i], i);
			
		for (i in 0...a.length)
			assertEquals(m.get(a[i]), i);
		
	}
	function testTools() {
		assertEquals(Type.getClass([1, 2, 3].zip([])), IntMap);
		assertEquals(Type.getClass('foo,bar'.split(',').zip([])), StringMap);
		assertEquals(Type.getClass([true, false].zip([])), AnyMap);
		assertEquals(Type.getClass([2.0, 3.0].zip([])), AnyMap);
		assertEquals(Type.getClass([function () {}].zip([])), cast FunctionMap);
	}
}
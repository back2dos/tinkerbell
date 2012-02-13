package collections;
import haxe.unit.TestCase;
import tink.collections.ObjectMap;

/**
 * ...
 * @author back2dos
 */

class MapTest extends TestCase {
	function testObjectMap() {
		var o = new ObjectMap(),
			vals = [
				function () return 5,
				function () return 6,
				{ foo: 1 },
				{ foo: 2 },
			];
		for (v in vals)
			o.set(v, v);
		vals[2].foo = 123456;
		vals[3].foo = 654321;
		for (v in vals)
			assertEquals(v, o.get(v));
		assertEquals(Lambda.count(o), 4);
		
	}
}
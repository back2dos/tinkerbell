package collections;
import haxe.unit.TestCase;
import tink.collections.map.IMap;
import tink.collections.map.IntMap;
import tink.collections.map.ObjectMap;
import tink.collections.map.StringMap;

/**
 * ...
 * @author back2dos
 */

class MapTest extends TestCase {
	function runMapTest<A>(map:IMap < A, A > , values:Array<A>) {
		values = values.concat(values);
		for (value in values)
			map.set(value, value);
		for (key in values) 
			assertEquals(key, map.get(key));		
	}
	function testObjectMap() {
		runMapTest(new ObjectMap(), [ { }, [], new A(), testObjectMap, 1, 1.2, true, "true", null]);
	}
	function testStringMap() {
		runMapTest(new StringMap(), 'foo,bar,baz,1,false'.split(','));
	}
	function testIntMap() {
		runMapTest(new IntMap(), [1, 2, 3, 4, 5]);		
	}
}
private class A {
	public function new() {}
}
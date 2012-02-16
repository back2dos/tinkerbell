package util;
import haxe.unit.TestCase;
import tink.reflect.Property;

/**
 * ...
 * @author back2dos
 */

class PropertyTest extends TestCase {

	public function new() {
		super();
	}
	function testProperty() {
		var a = new A(5);
		assertEquals(Property.get(a, 'test'), a.test);
		assertEquals(Property.get(a, '_test'), Reflect.field(a, '_test'));
		Property.set(a, 'test', 6);
		assertEquals(a.test, 6);
	}
}
class A {
	private var _test:Int;
	public var test(get_test, set_test):Int;
	public function new(test) {
		this.test = test;
	}
	function get_test() {
		return _test;
	}
	function set_test(param) {
		_test = param;
		return param;
	}
}
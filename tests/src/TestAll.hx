package ;
import haxe.unit.TestRunner;

/**
 * ...
 * @author back2dos
 */

class TestAll {
	static public function run() {
		var runner = new TestRunner();
		runner.add(new lang.ClsTest());
		runner.add(new lang.ExtTest());
		runner.add(new util.PropertyTest());
		runner.add(new markup.FastTest());
		runner.add(new markup.NodesTest());
		runner.run();
	}
}
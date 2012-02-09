package ;
import macro.BuildTest;
import markup.FastTest;
import markup.NodesTest;
import util.PropertyTest;
import haxe.unit.TestRunner;

/**
 * ...
 * @author back2dos
 */

class TestAll {
	static public function run() {
		var runner = new TestRunner();
		runner.add(new BuildTest());
		runner.add(new PropertyTest());
		runner.add(new FastTest());
		//runner.add(new NodesTest());
		runner.run();
	}
}
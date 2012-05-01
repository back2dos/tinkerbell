package ;
import haxe.unit.TestRunner;

/**
 * ...
 * @author back2dos
 */

class TestAll {
	static public function run() {
		var runner = new TestRunner();
		runner.add(new util.PropertyTest());
		runner.add(new lang.ClsTest());
		runner.add(new lang.ExtTest());
		runner.add(new lang.TinqTest());
		runner.add(new collections.MapTest());
		runner.add(new reactive.BindingsTest());
		runner.add(new markup.FastTest());
		runner.add(new markup.NodesTest());
		runner.add(new tween.TweenTest());
		runner.add(new ui.MetricsTest());
		runner.run();
	}
}
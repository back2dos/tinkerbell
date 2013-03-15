package ;

import haxe.unit.TestRunner;

class TestAll {
	static public function run() {
		var runner = new TestRunner();
		#if !cpp //these cause problems on cpp
		runner.add(new util.PropertyTest());
		runner.add(new markup.FastTest());
		runner.add(new markup.NodesTest());
		#end
		runner.add(new lang.ClsTest());
		runner.add(new collections.MapTest());
		runner.add(new reactive.BindingsTest());
		runner.add(new tween.TweenTest());
		runner.add(new ui.MetricsTest());
		runner.run();
	}
}
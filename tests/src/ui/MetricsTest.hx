package ui;

/**
 * ...
 * @author back2dos
 */
import haxe.unit.TestCase;
import tink.ui.core.Pair;

import tink.ui.core.Metrics;
import tink.ui.core.Size;

using tink.ui.core.Metrics;

class MetricsTest extends TestCase {
	function symPair<A>(v:A) {
		return new PlainPair(v, v);
	}
	function testMin() {
		var group = [
			new MockMetrics(symPair(50.0), symPair(.5), symPair(Min)),
			new MockMetrics(symPair(100.0), symPair(.0), symPair(Relative(1))),
			new MockMetrics(symPair(150.0), symPair(1.0), symPair(Relative(.5))),
		];
		assertEquals(150.0, group.minShort(true));
		assertEquals(300.0, group.minLong(true));
	}
	function testArrange() {
		var group = [
			new MockMetrics(symPair(50.0), symPair(.5), symPair(Relative(3))),
			new MockMetrics(symPair(100.0), symPair(.0), symPair(Relative(1))),
			new MockMetrics(symPair(150.0), symPair(1.0), symPair(Relative(.5))),
		];
		
		group.arrangeShort(true, 0, 600);
		
		assertEquals(600.0, group[0].dim.get(true));
		assertEquals(200.0, group[1].dim.get(true));
		assertEquals(150.0, group[2].dim.get(true));
		
		var min = group.minLong(true);
		
		group.arrangeLong(true, 0, min);
		for (m in group)
			assertEquals(m.dim.get(true), m.getMin(true));
		
		for (i in 0...10) {
			var total = min * (1 + 2 * Math.random());
			group.arrangeLong(true, 0, total);
			for (m in group)
				total -= m.dim.get(true);
			assertEquals(.0, total);
		}
	}
}
class MockMetrics extends Metrics {
	public var dim:PlainPair<Float>;
	public var pos:PlainPair<Float>;
	public function new(min, align, size) {
		dim = new PlainPair(.0, .0);
		pos = new PlainPair(.0, .0);
		super(min, align, size, pos.set, dim.set);
	}
}
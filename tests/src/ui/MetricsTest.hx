package ui;

/**
 * ...
 * @author back2dos
 */
import haxe.unit.TestCase;
import tink.ui.core.Pair;

import tink.ui.core.Metrics;

using tink.ui.core.Metrics;

class MetricsTest extends TestCase {
	function symPair<A>(v:A) {
		return new PlainPair(v, v);
	}
	function testMin() {
		var group = [
			new MockMetrics(symPair(50.0), symPair(.5), symPair(Math.NaN)),
			new MockMetrics(symPair(100.0), symPair(.0), symPair(1.0)),
			new MockMetrics(symPair(150.0), symPair(1.0), symPair(.5)),
		];
		var metrics = [];
		for (m in group) 
			metrics.push(m.metrics);
		assertEquals(150.0, metrics.minShort(true));
		assertEquals(300.0, metrics.minLong(true, 0));
	}
	function testArrange() {
		var group = [
			new MockMetrics(symPair(50.0), symPair(.5), symPair(3.0)),
			new MockMetrics(symPair(100.0), symPair(.0), symPair(1.0)),
			new MockMetrics(symPair(150.0), symPair(1.0), symPair(.5)),
		];
		var metrics = [];
		for (m in group) 
			metrics.push(m.metrics);
		
		metrics.arrangeShort(true, 0, 600);
		
		assertEquals(600.0, group[0].dim.get(true));
		assertEquals(200.0, group[1].dim.get(true));
		assertEquals(150.0, group[2].dim.get(true));
		
		var min = metrics.minLong(true, 0);
		
		metrics.arrangeLong(true, 0, min, 0);
		for (m in group)
			assertEquals(m.dim.get(true), m.metrics.getMin(true));
		
		for (i in 0...10) {
			var total:Float = Math.round(min * (1 + 2 * Math.random()));
			metrics.arrangeLong(true, 0, total, 0);
			for (m in group)
				total -= m.dim.get(true);
			assertTrue(Math.abs(total) < 1e-10);
		}
	}
}
class MockMetrics {
	public var dim:PlainPair<Float>;
	public var pos:PlainPair<Float>;
	public var metrics(default, null):Metrics;
	public function new(min, align, weight) {
		dim = new PlainPair(.0, .0);
		pos = new PlainPair(.0, .0);
		this.metrics = new Metrics(min, align, weight, pos.set, dim.set);
		//super(min, align, weight, pos.set, dim.set);
	}
}
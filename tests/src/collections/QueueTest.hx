package collections;
import haxe.unit.TestCase;
import tink.collections.queues.ArrayQueue;

/**
 * ...
 * @author back2dos
 */

class QueueTest extends TestCase {
	function testArrayQueue() {
		var q = new ArrayQueue(0);
		var a = [];
		for (i in 0...1000)
			a.push(i);
		var index = 0;
		while (index < a.length-1) {
			var start = index;
			var batch = Std.random(a.length - index);
			for (i in 0...batch) 
				q.add(a[index++]);
			assertEquals(q.count, batch);
			for (i in start...index)
				assertEquals(a[i], q.get());
		}		
	}
}
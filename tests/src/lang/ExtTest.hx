package lang;

import haxe.unit.TestCase;
import tink.lang.Ext;

using lang.ExtTest;
using Lambda;

class ExtTest extends TestCase {

	public function new() {
		super();
	}
	function test() {
		var x = new X(),
			h1 = function (x, y) { },
			h2 = function (foo) { };
			
		x.declare('on');
		x.declare('bar');
		x.declare('foo', 5);
			
		x.onPoint(h1);
		x.foo(h2);
		
		assertEquals(x.bar(), x);
		assertEquals(x.baz(), 5);
		
		var a:Array<Call> = [];
		a.push( { method: 'on', args: ['point', h1], ret: null } );
		a.push( { method: 'on', args: ['foo', h2], ret: null } );
		a.push( { method: 'bar', args: [], ret: null } );
		a.push( { method: 'foo', args: [], ret: 5 } );
		
		assertEquals(a.length, x.count());
		for (c in x) {
			var e = a.shift();
			assertEquals(e.method, c.method);
			assertEquals(e.ret, c.ret);
			var c = c.args.copy();
			for (a in e.args)
				assertEquals(a, c.shift());
		}
	}
	
}
extern class XExt implements Ext<X> {
	@:event('point') function onPoint(x:Int, y:Int);
	@:event function foo(foo:String);
	@:native function bar();
	@:native('foo') function baz():Int;
}
private typedef Call = {
	method:String,
	args:Array<Dynamic>,
	ret:Dynamic
}
private class X implements Dynamic {
	var calls:Array<Call>;
	public function new() {
		this.calls = [];
	}
	public function declare(name:String, ?ret:Dynamic = null) {
		Reflect.setField(this, name, Reflect.makeVarArgs(callback(handleCall, ret, name)));
	}
	function handleCall(ret:Dynamic, method:String, args:Array<Dynamic>) {
		this.calls.push( { method:method, args:args, ret:ret } );
		return ret;
	}
	public function iterator() {
		return calls.iterator();
	}
	function toString():String {
		return '[Just a little "X"]';
	}
}
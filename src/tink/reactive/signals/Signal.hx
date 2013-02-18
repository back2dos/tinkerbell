package tink.reactive.signals;

import tink.collections.sets.ArraySet;
import tink.lang.Cls;

typedef Named<Const, T> = T;

interface VoidSignal {
	function on(handler:Void->Void):Void;
	function un(handler:Void->Void):Void;	
	function once(handler:Void->Void):Void;
}

interface Signal<T> {
	function on(handler:T->Void):Void;
	function un(handler:T->Void):Void;
	function once(handler:T->Void):Void;
}
private interface SignalBase<F> extends Cls {
	var handlers:ArraySet<F> = new ArraySet();
	var single:ArraySet<F> = new ArraySet();
	public function on(handler:F):Void {
		single.remove(handler);
		handlers.add(handler);
	}
	function all():Array<F> {
		var ret = untyped single.a.concat(handlers.a);
		single = new ArraySet();
		return ret;
	}
	public function un(handler:F):Void 
		handlers.remove(handler) || single.remove(handler)
		
	public function once(handler:F):Void 
		handlers.contains(handler) || single.add(handler)
}

class SimpleSignal<T> implements SignalBase<T->Void> implements Signal<T> {
	public function new() {}
	public function fire(data:T) 
		for (h in all()) h(data)
		
	static public function map<S, T>(source:Signal<T>, map:T->S) {
		var ret = new SimpleSignal();
		source.on(function (d) ret.fire(map(d)));
		return ret;
	}
}

class SimpleVoidSignal implements SignalBase<Void->Void> implements VoidSignal {
	public function new() {}
	public function fire() 
		for (h in all()) h()
}
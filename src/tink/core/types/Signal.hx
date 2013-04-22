package tink.core.types;

import tink.core.types.Callback;

enum Noise { Noise; }

abstract Signal<T>(Callback<T>->CallbackLink) {
	public inline function new(f:Callback<T>->CallbackLink) this = f;	
	public function watch(handler:Callback<T>):CallbackLink 
		return (this)(handler);
	public function map<A>(f:T->A):Signal<A> 
		return new Signal(function (cb) return (this)(function (result) cb.invoke(f(result))));
	public function next():Future<T> 
		return Future.ofAsyncCall(watch.bind(this));
	public function noise():Signal<Noise>
		return map(this, function (_) return Noise);
		
	public function dike():Signal<T> {
		var ret = new CallbackList<T>();
		watch(this, ret.invoke);
		return ret;
	}
}
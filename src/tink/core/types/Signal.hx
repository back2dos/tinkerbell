package tink.core.types;

import tink.core.types.Callback;

enum Noise { Noise; }

abstract Signal<T>(Callback<T>->CallbackLink) {
	public inline function new(f:Callback<T>->CallbackLink) this = f;	
	public function watch(handler:Callback<T>):CallbackLink 
		return (this)(handler);
	public function when(cb) return watch(cb);			
	public function map<A>(f:T->A):Signal<A> 
		return new Signal(function (cb) return (this)(function (result) cb.invoke(f(result))));
	public function next():Future<T> {
		var ret = Future.create();
		watch(ret.invoke);
		return ret.asFuture();
	}
	public function noise():Signal<Noise>
		return map(function (_) return Noise);
		
	public function dike():Signal<T> {
		var ret = new CallbackList<T>();
		watch(ret.invoke);
		return ret;
	}
	
	public function filter(f:T->Bool, ?dike = true):Signal<T> {
		var ret = new Signal(function (cb) return when(this, function (result) if (f(result)) cb.invoke(result)));
		return
			if (dike) ret.dike();
			else ret;
	}	
	
	public function join(other:Signal<T>, ?dike = true):Signal<T> {
		var ret = new Signal(
			function (cb:Callback<T>):CallbackLink 
				return [
					when(this, cb),
					other.when(cb)
				]
		);
		return
			if (dike) ret.dike();
			else ret;
	}	
	//@:to function toFunction():Callback<T>->CallbackLink return this;
}
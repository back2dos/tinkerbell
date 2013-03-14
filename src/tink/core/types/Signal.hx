package tink.core.types;

import tink.core.types.Callback;

abstract Signal<T>((T->Void)->CallbackLink) {

	public inline function new(f:(T->Void)->CallbackLink) this = f;	
	
	public function watch(handler:Callback<T>):CallbackLink 
		return asFunction(this)(handler);
		
	public function map<A>(f:T->A):Signal<A> 
		return new Signal(function (handler) return asFunction(this)(function (result) handler(f(result))));
	
	inline function asFunction():(T->Void)->CallbackLink return this;	
}
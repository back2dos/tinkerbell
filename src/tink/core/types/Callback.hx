package tink.core.types;

typedef Callback<T> = T->Void;

abstract CallbackLink(Void->Bool) {
	public inline function new(link:Void->Bool) this = link;
	public function cancel():Bool return asFunction(this)();
	inline function asFunction():Void->Bool return this;	
	@:from static inline function fromFunction(f:Void->Bool) return new CallbackLink(f);
}

//TODO: There's a lot of room for optimization here
abstract CallbackList<T>(Array<Callback<T>>) {
	public inline function new() this = [];
	public function add(cb:Callback<T>):CallbackLink {
		var f = function (v) cb(v);
		this.push(f);
		return new CallbackLink(function () return this.remove(f));
	}
	public function invoke(data:T) 
		for (f in this.copy()) f(data);
}
package tink.core.types;

abstract Callback<T>(T->Void) from (T->Void) {
	inline function new(f) 
		this = f;
	public inline function invoke(data:T):Void 
		(this)(data);
	@:from static inline function fromNiladic<A>(f:Void->Void):Callback<A> 
		return new Callback(function (r) f());
}

abstract CallbackLink(Void->Void) {
	inline function new(link:Void->Void) 
		this = link;
	public function dissolve():Void 
		if (this != null) asFunction(this)();
	inline function asFunction():Void->Void 
		return this;	
	@:from static inline function fromFunction(f:Void->Void) 
		return new CallbackLink(f);
}

private class Cell<T> {
	//TODO: the cell (or some super class of it) could just as easily act as callback link
	public var cb:Callback<T>;
	function new() {}
	public inline function free():Void {
		this.cb = null;
		pool.push(this);
	}
	static var pool:Array<Cell<Dynamic>> = [];
	static public inline function get<A>():Cell<A> 
		return
			if (pool.length > 0)cast pool.pop();
			else new Cell();
}

abstract CallbackList<T>(Array<Cell<T>>) {
	public var length(get, never):Int;
	public inline function new() 
		this = [];
	inline function get_length():Int 
		return this.length;	
	public function add(cb:Callback<T>):CallbackLink {
		var cell = Cell.get();
		cell.cb = cb;
		this.push(cell);
		return function () {
			this.remove(cell);
			cell.free();
		}
	}
	@:to public function toSignal():Signal<T> 
		return new Signal(add.bind(this));
		
	public function invoke(data:T) 
		for (cell in this.copy()) 
			cell.cb.invoke(data);			
	public function clear():Void 
		for (cell in this.splice(0, this.length)) 
			cell.free();
}
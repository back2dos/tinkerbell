package tink.core.types;

abstract Future<T>((T->Void)->(Void->Bool)) {

	public inline function new(f:(T->Void)->(Void->Bool)) this = f;	
	
	public function get(handler) {
		return asFunction(this)(handler);
	}
	public function map<A>(f:T->A):Future<A> {
		return new Future(function (handler) return asFunction(this)(function (result) handler(f(result))));
	}
	public function flatMap<A>(next:T->Future<A>):Future<A> {
		return flatten(map(this, next));
	}
	static public function flatten<A>(f:Future<Future<A>>):Future<A> {
		return new Future(function (handler) {
			var ret = null;
			ret = f.get(function (next:Future<A>) {
				ret = next.get(function (result) handler(result));
			});
			return ret;
		});
	}
	public inline function asFunction():(T->Void)->(Void->Bool) return this;
	
	static function uncancelable():Bool return false;
	
	@:from static public function futures<A>(futures:Array<Future<A>>) {
		var ret = ofConstant([]);
		for (f in futures)
			ret = ret.flatMap(
				function (results:Array<A>) 
					return f.map(
						function (result) 
							return results.concat([result])
					)
			);
		return ret;
	}
	
	@:noUsing static public function ofConstant<A>(v:A):Future<A> 
		return new Future(function (handler) { handler(v); return uncancelable; } );
		
	@:noUsing static public function ofAsyncCall<A>(f:(A->Void)->Void):Future<A> {
		var state = Pending([]);
		f(function (result) {
			var old = state;
			state = Done(result);
			switch (old) {
				case Pending(handlers): 
					for (h in handlers.splice(0, handlers.length)) h.f(result);
				case Done(_):
					//TODO: do something meaningful here. In the worst case panic and throw an exception. ERMERGHERD!
			}
		});
		return 
			new Future(
				function (handler)
					return 
						switch (state) {
							case Pending(handlers):
								var boxed = { f: handler };
								handlers.push(boxed);
								function () return handlers.remove(boxed);
							case Done(result): 
								handler(result);
								uncancelable;
						}
			);
	}
	//@:noUsing static public function doGet<A>(f:Future<A>, handler) return f.get(handler);	
	
}

private enum State<T> {
	Pending(handlers:Array<{ f: T->Void }>);//TODO: at some point this should maybe become a double linked list instead as it should be faster and smaller. Do some profiling concerning that.
	Done(result:T);
}
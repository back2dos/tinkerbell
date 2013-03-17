package tink.core.types;

import tink.core.types.Callback;

abstract Future<T>((T->Void)->CallbackLink) {

	public inline function new(f:(T->Void)->CallbackLink) this = f;	
	
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
	public inline function asFunction():(T->Void)->CallbackLink return this;
	
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
		var state = Pending(new CallbackList());
		f(function (result) {
			var old = state;
			state = Done(result);
			switch (old) {
				case Pending(handlers): 
					handlers.invoke(result);
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
								handlers.add(handler);
							case Done(result): 
								handler(result);
								uncancelable;
						}
			);
	}	
}

private enum State<T> {
	Pending(handlers:CallbackList<T>);
	Done(result:T);
}
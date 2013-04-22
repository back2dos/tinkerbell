package tink.core.types;

import tink.core.types.Callback;
import tink.core.types.Outcome;

abstract Future<T>(Callback<T>->CallbackLink) {

	public inline function new(f:Callback<T>->CallbackLink) this = f;	
	
	public function get(callback:Callback<T>):CallbackLink {
		return (this)(callback);
	}
	static public function done<D, F>(s:Surprise<D, F>, callback:Callback<D>):Void {
		s.get(function (o) switch o {
			case Success(d): callback.invoke(d);
			default:
		});
	}
	static public function failed<D, F>(s:Future<Outcome<D, F>>, callback:Callback<F>):Void {
		s.get(function (o) switch o {
			case Failure(f): callback.invoke(f);
			default:
		});
	}
	static public function tryMap<D, F, R>(s:Surprise<D, F>, f:D->R):Surprise<R, F> {
		return s.map(function (o) return switch o {
			case Success(d): Success(f(d));
			case Failure(f): Failure(f);
		});
	}
	public function map<A>(f:T->A):Future<A> {
		return new Future(function (callback) return (this)(function (result) callback.invoke(f(result))));
	}
	public function flatMap<A>(next:T->Future<A>):Future<A> {
		return flatten(map(this, next));
	}
	static public function flatten<A>(f:Future<Future<A>>):Future<A> {
		return new Future(function (callback) {
			var ret = null;
			ret = f.get(function (next:Future<A>) {
				ret = next.get(function (result) callback.invoke(result));
			});
			return ret;
		});
	}
	
	@:from static function fromMany<A>(futures:Array<Future<A>>):Future<Array<A>> {
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
		return new Future(function (callback) { callback.invoke(v); return null; } );
		
	@:noUsing static public function ofAsyncCall<A>(f:(A->Void)->Void):Future<A> {
		var state = Pending(new CallbackList());
		f(function (result) {
			var old = state;
			state = Done(result);
			switch (old) {
				case Pending(callbacks): 
					callbacks.invoke(result);
					callbacks.clear();
				case Done(_):
					//TODO: do something meaningful here. In the worst case panic and throw an exception. ERMERGHERD!
			}
		});
		return 
			new Future(
				function (callback)
					return 
						switch (state) {
							case Pending(callbacks):
								callbacks.add(callback);
							case Done(result): 
								callback.invoke(result);
								null;
						}
			);
	}	
}

private enum State<T> {
	Pending(callbacks:CallbackList<T>);
	Done(result:T);
}

typedef Surprise<D, F> = Future<Outcome<D, F>>;

abstract LeftFailingHandler<D, F>(F->D->Void) {
	public function new(f) this = f;
}
abstract RightFailingHandler<D, F>(D->F->Void) {
	public function new(f) this = f;	
}
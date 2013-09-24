package tink.core.types;

import tink.core.types.Callback;
import tink.core.types.Outcome;

abstract Future<T>(Callback<T>->CallbackLink) {

	public inline function new(f:Callback<T>->CallbackLink) this = f;	
	public inline function get(callback:Callback<T>):CallbackLink 
		return (this)(callback);
	public inline function when(cb:Callback<T>) return get(cb);	
	/*static public function done<D, F>(s:Surprise<D, F>, callback:Callback<D>):Void {
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
	}*/
	
	//@:to function toFunction():Callback<T>->CallbackLink return this;
	public function map<A>(f:T->A):Future<A> {
		return new Future(function (callback) return (this)(function (result) callback.invoke(f(result))));
	}
	public function flatMap<A>(next:T->Future<A>):Future<A> {
		return flatten(map(next));
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
	// @:from static function fromOp<A>(op:FutureOp<A>):Future<A> { //this appears to be called when clearly it shouldn't
	// 	return op.asFuture();
	// }
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
		var op = create();
		f(op.invoke);
		return op.asFuture();
	}
	@:noUsing static public inline function create<A>():FutureOp<A> {
		return new FutureOp();
	}
	@:to public function toSurprise<F>():Surprise<T, F> {
		return map(Success);
	}
}

class FutureOp<T> {
	var state:State<T>;
	var future:Future<T>;
	public function new() {
		state = Pending(new CallbackList());
		future = new Future(
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
	public function asFuture() return future;
	public function invoke(result:T):Bool {
		return
			switch (state) {
				case Pending(callbacks):
					state = Done(result);
					callbacks.invoke(result);
					callbacks.clear();
					true;
				case Done(_):
					false;
			}
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
package tink.lang;

import tink.core.types.Future;
import tink.core.types.Surprise;
import tink.core.types.Outcome;
import tink.core.types.Callback;

private typedef Plain<T> = CollectorOp<T>;
private typedef Unsafe<D, F> = CollectorOp<Outcome<D, F>>;

abstract CollectorOp<T>(Future<T>) {
	public function get(handler:T -> Void):CallbackLink
		return this.get(handler);	
	
	@:from static function fromLeft<D, F>(h:LeftFailingHandler<D, F>->Void):Unsafe<D, F> 
		return 
			Future.ofAsyncCall(
				function (handler) 
					h(new LeftFailingHandler(function (error, result) 
						handler( 
							if (error == null) Outcome.Success(result)
							else Outcome.Failure(error)
						)
					))
			);
	
	@:from static function fromFutureOutcome<D, F>(f:Surprise<D, F>):Unsafe<D, F> return cast f;
	
	@:from static function fromFuture<A, B>(f:Future<A>):Unsafe<A, B> 
		return f.map(function (v):Outcome<A, B> return Success(v));
	
	@:from static function fromOutcome<D, F>(f:Outcome<D, F>):Unsafe<D, F> return Future.ofConstant(f);	
	
	@:from static public function fromInt<F>(v:Int):Unsafe<Int, F> return fromAny(v);
	@:from static function fromAny<A, B>(v:A):Unsafe<A, B> return fromFuture(Future.ofConstant(v));
	
	static public function promote<X>(s:CollectorOp<X>) return s;
}
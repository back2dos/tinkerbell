package tink.lang.helpers;

import tink.core.types.Signal;
import tink.core.types.Future;
import tink.core.types.Outcome;
import tink.core.types.Callback;

private typedef Plain<T> = CollectorOp<T>;
private typedef Unsafe<D, F> = CollectorOp<Outcome<D, F>>;

abstract CollectorOp<T>(Future<T>) {
	public function get(handler:Callback<T>):CallbackLink
		return this.get(handler);	
	
	@:from static function fromLeft<D, F>(h:LeftFailingHandler<D, F>->Void):Unsafe<D, F> 
		return 
			Future.ofAsyncCall(
				function (handler) 
					h(new LeftFailingHandler(function (error:F, result:D) 
						handler( 
							if (error == null) Outcome.Success(result)
							else Outcome.Failure(error)
						)
					))
			);
	
				
	@:from static function fromSurprises<D, F>(f:Array<Surprise<D, F>>):Unsafe<Array<D>, F> {
		var f:Future<Array<Outcome<D, F>>> = f;
		//TODO: Fail early rather then accumulating all failures first
		return f.map(
			function (result) {
				var ret = [];
				for (r in result)
					switch (r) {
						case Success(d): ret.push(d);
						case Failure(f): return Failure(f);
					}
				return Success(ret);
			}
		);
	}
	
	@:from static inline function fromSurprise<D, F>(f:Surprise<D, F>):Unsafe<D, F> return cast f;
	
	@:from static inline function fromFuture<A, B>(f:Future<A>):Unsafe<A, B> 
		return f.map(function (v):Outcome<A, B> return Success(v));
	
	@:from static inline function fromOutcome<D, F>(f:Outcome<D, F>):Unsafe<D, F> return Future.ofConstant(f);	
	
	//TODO: for some strange reason ints sometimes become floats here
	@:from static inline public function fromAny<A, B>(v:A):Unsafe<A, B> return fromFuture(Future.ofConstant(v));	
	
	static public inline function promote<X>(s:CollectorOp<X>):CollectorOp<X> return s;
	static public inline function demote<X>(s:Result<X>):Result<X> return s;	
}

private abstract Result<T>(Future<T>) {
	private inline function new(f:Future<T>) this = f;
	@:from static function fromFake<A>(s:Unsafe<A, Class<Void>>):Result<A> {
		return 
			new Result(fromReal(s).toFuture().map(
				function (o) 
					return switch o {
						case Success(d): d;
						default: throw 'assert';
					}
			));
	}
	@:from static function fromReal<D, F>(s:Unsafe<D, F>):Result<Outcome<D, F>> {
		return cast s;
	}
	public inline function toFuture():Future<T> return this;
}
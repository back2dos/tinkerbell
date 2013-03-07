package tink.core.types;

abstract Surprise<D, F>(Future<Outcome<D, F>>) {
	public function get(handler:Outcome<D, F> -> Void):Void->Bool
		return this.get(handler);
	
	@:to static public function fakeToFuture<A>(s:Future<Outcome<A, Class<Void>>>):Future<A> 
		return 
			s.map(function (o) 
				return switch (o) { 
					case Success(d): d; 
					default: throw 'assert'; //TODO: Class<Void> really has no useful meaning so whoever runs into this was asking for trouble. However it might be prudent to add some static analysis to avoid any of this is left in Context.onGenerate
				}
			);
	
	@:to static public function realToFuture<D, F>(s:Future<Outcome<D, F>>):Future<Outcome<D, F>> return s;
	
	@:from static public function fromLeft<D, F>(h:LeftFailingHandler<D, F>->Void):Surprise<D, F> 
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
	
	@:from static public function fromFutureOutcome<D, F>(f:Future<Outcome<D, F>>):Surprise<D, F> return f;
	
	@:from static public function fromFuture<A, B>(f:Future<A>):Surprise<A, B> 
		return f.map(function (v):Outcome<A, B> return Success(v));
	
	@:from static public function fromOutcome<D, F>(f:Outcome<D, F>):Surprise<D, F> return f;
	
	@:from static public function fromInt<B>(v:Int):Surprise<Int, B> return fromFuture(Future.ofConstant(v));
	
	@:from static public function fromAny<A, B>(v:A):Surprise < A, B > return fromFuture(Future.ofConstant(v));
	
	static public inline function promote<D, F>(s:Surprise<D, F>) return s;
}

abstract LeftFailingHandler<D, F>(F->D->Void) {
	public function new(f) this = f;
}
abstract RightFailingHandler<D, F>(D->F->Void) {
	public function new(f) this = f;	
}
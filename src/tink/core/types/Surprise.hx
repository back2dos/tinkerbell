package tink.core.types;

import tink.core.types.Future;
import tink.core.types.Outcome;

typedef Surprise<S, F> = Future<Outcome<S, F>>;

class SurpriseTools {
	static public function map<A, B, F>(f:Surprise<A, F>, map:A->B):Surprise<B, F>
		return 
			FutureTools.map(f, function (outcome) 
				return
					switch (outcome) {
						case Success(s): Success(map(s));
						case Failure(f): Failure(f);
					}
			)
			
	static public function chain<A, B, F>(f:Surprise<A, F>, next:A->Surprise<B, F>):Surprise<B, F>
		return
			FutureTools.chain(f, function (result) 
				return
					switch (result) {
						case Success(result): next(result);
						case Failure(error): function (handler) handler(Failure(error));
					}
			)
			
	static public function merge<A, F>(fs:Array<Surprise<A, F>>):Surprise<Array<A>, F> {
		var ret = function (handler) handler(Success([]));
		for (f in fs)
			ret = chain(
				ret, 
				function (result:Array<A>) 
					return map(f, function (a:A) return result.concat([a]))
			);
		return ret;
	}			
	static public function handle<S, F>(f:Surprise<S, F>, ?process:S->Void, ?recover:F->Void, ?finally:Void->Void) {
		f(function (outcome) {
			switch (outcome) {
				case Success(s):
					if (process != null) process(s);
				case Failure(f):
					if (recover != null) recover(f);
			}
			if (finally != null) finally();
		});
		return f;
	}
	
}
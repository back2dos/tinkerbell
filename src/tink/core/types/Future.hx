package tink.core.types;

import tink.core.types.Outcome;

typedef Future<T> = (T->Void)->Void;

class FutureTools {
	static public function chain<A, B>(f:Future<A>, next:A->Future<B>):Future<B> {
		var handlers = [],
			actual = null;
		f(function (r) {	
			actual = next(r);
			for (h in handlers) 
				actual(h);
			handlers = null;
		});
		return 
			function (h) {
				if (actual == null) handlers.push(h);
				else actual(h);
			}
	}
	
	static public function map<A, B>(f:Future<A>, map:A->B):Future<B>
		return 
			function (handler) 
				f(function (result) 
					handler(map(result))
				)
}

class FutureOutcomeTools {
	static public function map<A, B, F>(f:Future<Outcome<A, F>>, map:A->B):Future<Outcome<B, F>>
		return 
			FutureTools.map(f, function (outcome) 
				return
					switch (outcome) {
						case Success(s): Success(map(s));
						case Failure(f): Failure(f);
					}
			)
			
	static public function chain<A, B, F>(f:Future<Outcome<A, F>>, next:A->Future<Outcome<B, F>>):Future<Outcome<B, F>>
		return
			FutureTools.chain(f, function (result) 
				return
					switch (result) {
						case Success(result): next(result);
						case Failure(error): function (handler) handler(Failure(error));
					}
			)
			
	static public function handle < S, F > (f:Future < Outcome < S, F >> , ?process:S->Void, ?recover:F->Void, ?finally:Void->Void) {
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
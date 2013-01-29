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
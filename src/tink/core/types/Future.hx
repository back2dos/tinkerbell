package tink.core.types;

import tink.core.types.Outcome;

//TODO: this is probably unclever as there is no distinction between an operation to register callbacks on, and a factory for such operations
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
	static public function merge<A>(fs:Array<Future<A>>):Future<Array<A>> {
		var ret = function (handler) handler([]);
		for (f in fs)
			ret = chain(
				ret, 
				function (result:Array<A>) 
					return map(f, function (a:A) return result.concat([a]))
			);
		return ret;
	}
	
	static public function map<A, B>(f:Future<A>, map:A->B):Future<B>
		return 
			function (handler) 
				f(function (result) 
					handler(map(result))
				)
}
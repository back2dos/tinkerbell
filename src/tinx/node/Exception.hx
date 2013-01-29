package tinx.node;

import tink.core.types.*;

typedef Exception = Dynamic;
typedef UnsafeResult<T> = Outcome<T, Exception>;
typedef Unsafe<T> = Surprise<T, Exception>;
typedef Handler<T> = Exception->T->Void;

typedef Sugar = Surprise.SurpriseTools;

class HandlerFuture<T> {
	var handlers:Array<UnsafeResult<T>->Void>;
	var result:UnsafeResult<T>;
	public function new() 
		handlers = []
	
	public function get(handle)
		if (handlers != null)
			handlers.push(handle)
		else
			handle(result)
	
	public function fire(err:Exception, data:T) {
		result = 
			if (err == null) Success(data);
			else Failure(err);
		var old = handlers;
		handlers = null;
		for (h in old) h(result);
	}
	static public function future<A>(f:Handler<A>->Void):Unsafe<A> {
		var ret = new HandlerFuture();
		f(ret.fire);
		return ret.get;
	}
}
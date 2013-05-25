package tinx.node.events;

import tink.core.types.Signal;
import tink.core.types.Future;

typedef Emitter = {
	function addListener(type:String, handler:Dynamic):Void;
	function removeListener(type:String, handler:Dynamic):Void;
	function once(type:String, handler:Dynamic):Void;
}

class EmitterTools {
	static public function makeFutureNoise(target, name) 
		return makeFuture(target, name).map(function (_) return Noise);
		
	static public function makeFuture<A>(target:Emitter, name:String):Future<A> 
		return makeSignal(target, name).next();
	
	static public function makeSignal<A>(target:Emitter, name:String):Signal<A> {
		return new Signal(function (cb) {
			function f(data) cb.invoke(data);
			target.addListener(name, f);
			return target.removeListener.bind(name, f);
		});
	}
}
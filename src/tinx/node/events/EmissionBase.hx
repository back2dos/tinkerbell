package tinx.node.events;

import tink.lang.Cls;

class EmissionBase<F> implements Cls {
	var target:Emitter = _;
	var type:String = _;
	public function on(handler:F):Void
		target.addListener(type, handler)
	public function un(handler:F):Void 
		target.removeListener(type, handler)
	public function once(handler:F):Void 
		target.once(type, handler)
}
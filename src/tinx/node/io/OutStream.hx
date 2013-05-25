package tinx.node.io;

import tink.core.types.Future;
import tink.lang.Cls;
import tinx.node.*;
import tinx.node.events.*;

using tinx.node.events.Emitter;

class OutStream implements Cls {
	@:forward(writable) inline var target:NativeOut = _;
	
	@:signal var drain = target.makeSignal('drain');
	
	@:prop var encoding = 'utf8';
	
	public function write(v:Dynamic):Bool 
		//TODO: Rather than returning a bool here, one might consider return a future that triggers immediately if write succeeds or otherwise as soon as drain occurs
		return
			if (Buffer.isBuffer(v)) 
				target.write(v)
			else 
				target.write(Std.string(v), encoding);
	
	public function end(?v:Dynamic) {
		if (Buffer.isBuffer(v)) 
			target.end(v)
		else if (v != null)
			target.end(Std.string(v), encoding);
		else
			target.end();
		return target.makeFutureNoise('finish');
	}
	
}

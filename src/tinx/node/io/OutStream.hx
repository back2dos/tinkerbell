package tinx.node.io;

import tink.lang.Cls;
import tinx.node.*;
import tinx.node.events.*;

class OutStream implements Cls {
	@:forward inline var target:NativeOut = _;
	
	@:signal var drain = new VoidEmission(target, 'drain');
	@:signal var close = new VoidEmission(target, 'close');
	@:signal var error:Error = new Emission(target, 'error');	
	
	@:prop var encoding = 'utf8';
	
	public function write(v:Dynamic) 
		return
			if (Buffer.isBuffer(v)) 
				target.write(v)
			else 
				target.write(Std.string(v), encoding);
	
	public function end(?v:Dynamic)
		if (Buffer.isBuffer(v)) 
			target.end(v)
		else if (v != null)
			target.end(Std.string(v), encoding);
	
}

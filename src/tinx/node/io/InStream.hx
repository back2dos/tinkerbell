package tinx.node.io;

import tink.lang.Cls;
import tink.reactive.signals.Signal;

import tinx.node.events.*;
import tinx.node.*;

using tink.reactive.signals.Signal;

private typedef In = NativeIn;//TODO: this circumvents some weird bug

class InStream implements Cls {
	@:forward inline var target:In = _;
	
	@:signal var data:Buffer = new Emission(target, 'data');
	@:signal var end = new VoidEmission(target, 'end');
	@:signal var close = new VoidEmission(target, 'close');
	@:signal var error:Exception = new Emission(target, 'error');
	
	var encoded:Hash<Signal<String>> = new Hash();
	
	public function decode(?encoding = 'utf8'):Signal<String> {
		if (!encoded.exists(encoding)) 
			encoded.set(
				encoding, 
				data.map(function (data) return data.toString(encoding))
			);
		return encoded.get(encoding);
	}
	public function get(handler:Buffer->Void):Void {
		var bufs:Array<Buffer> = [];
		@on(data) 
			bufs.push(data);
		@on(end) 
			handler(Buffer.concat(bufs));
	}
}
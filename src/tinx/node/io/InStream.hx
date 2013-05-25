package tinx.node.io;

import haxe.ds.StringMap;
import tink.core.types.*;
import tink.lang.Cls;

import tinx.node.events.*;
import tinx.node.*;

using tinx.node.events.Emitter;

private typedef In = NativeIn;//TODO: this circumvents some weird bug

class InStream implements Cls {
	@:forward(readable, pause, resume, destroy) 
	inline var target:In = _;
	
	@:read var end:Future<InStream> = target.makeFuture('end').map(function (_) return this);
	@:read var error:Future<Error> = target.makeFuture('error');
	
	@:signal var data:Buffer = target.makeSignal('data');
	//var encoded:StringMap<Signal<String>> = new StringMap();
	//
	//public function decode(?encoding = 'utf8'):Signal<String> {
		//if (!encoded.exists(encoding)) 
			//encoded.set(
				//encoding, 
				//data.map(function (data) return data.toString(encoding))
			//);
		//return encoded.get(encoding);
	//}
	public function all() 
		return 
			Future.ofAsyncCall(
				function (handler) {
					var bufs:Array<Buffer> = [];
					data.watch(function (data) {
						if (!Buffer.isBuffer(data))
							data = new Buffer(cast data);
						bufs.push(data);						
					});
					error.get(function (error) handler(Outcome.Failure(error)));
					end.get(function () handler(Outcome.Success(Buffer.concat(bufs))));
				}
			);
	
}
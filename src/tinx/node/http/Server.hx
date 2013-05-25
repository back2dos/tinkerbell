package tinx.node.http;

import tink.core.types.Signal;
import tink.lang.Cls;
import tinx.node.Runtime;

using tinx.node.events.Emitter;

private typedef Native = {>Emitter,
	function listen(port:Int, host:String):Void;
	function close():Void;
}

class Server implements Cls {
	var native:Native = Runtime.load('http').createServer(handleRequest);
	
	@:signal var request:Request;
	@:future var closed:Noise = native.makeFutureNoise('close');
		
	function handleRequest(request, response) 
		_request.invoke(new Request(this, request, response));
	
	public function destroy() 
		native.close();
		
	static public function bind(port:Int, ?host = 'localhost') {
		var ret = new Server();
		ret.native.listen(port, host);
		return ret;
	}	
}
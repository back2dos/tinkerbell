package tinx.node.http;

import tink.core.types.Signal;
import tink.lang.Cls;
import tinx.node.Runtime;

using tinx.node.events.Emitter;

private typedef Native = { > Emitter,
	function listen(port:Int, ?host:String):Void;
	function close():Void;
}

class Server implements Cls {
	var native:Native = Runtime.load('http').createServer(handleRequest);
	
	@:signal var request:Request;
	@:future var closed:Noise = native.makeFutureNoise('close');
		
	function handleRequest(request, response) {
		var request = new Request(this, request, response);
		if (Reflect.field(request.headers, 'content-type') == 'application/x-www-form-urlencoded') {
			raw: request.getPostData()
		} => {
			@:privateAccess (request.params = raw);
			_request.invoke(request);
			true;
		}
		else 
			_request.invoke(request);
	}
	
	public function destroy() 
		native.close();
		
	static public function bind(port:Int, ?host:String) {
		var ret = new Server();
		if (host != null) 
			ret.native.listen(port, host);
		else 
			ret.native.listen(port);
		return ret;
	}	
}
package tinx.node.http;

import tink.lang.Cls;

import tinx.node.Lib;
import tinx.node.events.*;

class Server implements Cls {
	var native:Dynamic = Lib.module('http').createServer(handleRequest);
	
	@:signal var request:Request;
	@:signal var close = new VoidEmission(native, 'close');
		
	function handleRequest(request, response) 
		_request.fire(new Request(this, request, response))
	
	public function destroy() 
		native.close()
		
	static public function bind(port:Int, ?host = 'localhost') {
		var ret = new Server();
		ret.native.listen(port, host);
		return ret;
	}	
}

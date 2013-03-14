package tinx.node.http;

import tinx.node.io.*;

private typedef NativeRequest = {>NativeIn,
	var connection:Dynamic;
	var headers:Headers;
	var trailers:Headers;
	var url:String;
	var httpVersion:String;
	var method:String;
}

class Request extends InStream {
	@:read var server:Server = _;
	@:forward var request:NativeRequest = _;
	
	var response:Dynamic = _;
	
	function new() 
		super(request);
	
	public function trailers(handler) 
		if (request.readable)
			@on(end) 
				handler(request.trailers)
		else
			handler(request.trailers);
	
	public function respond(?status = 200, ?reason:String, ?headers:Headers) {
		response.writeHead(status, reason, headers);
		return new Response(response);
	}
}
package tinx.node.http;

import tinx.node.io.*;

using StringTools;

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
	public function getCookies():Map<String, String> {
		var ret = new Map();
		if (request.headers.cookie != null)
			ret.set(for (part in request.headers.cookie.split(';')) {
				var index = part.indexOf('=');
				$(part.substr(0, index).trim(), part.substr(index + 1).trim());
			});
		return ret;
	}
	function new() 
		super(request);
	
	public function trailers(handler) 
		end.get(function () handler(request.trailers));
	
	public function respond(?status = 200, ?reason:String, ?headers:Headers) {
		response.writeHead(status, reason, headers);
		return new Response(response);
	}
}
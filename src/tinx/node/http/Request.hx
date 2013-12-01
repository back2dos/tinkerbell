package tinx.node.http;

import haxe.ds.StringMap;
import tinx.node.Error;
import tinx.node.io.*;
import tinx.node.Runtime;

import tink.core.types.Outcome;

using StringTools;

private typedef NativeRequest = {>NativeIn,
	var connection:Dynamic;
	var headers:Headers;
	var trailers:Headers;
	var url:String;
	var httpVersion:String;
	var method:String;
}

abstract Values(Dynamic<String>) {
	public function new(of) {
		this = of;
	}

	@:arrayAccess function getArray(key:Array<String>):Array<String> {
		return 
			switch get(key[0] + '[]') {
				case Success(s): 
					if (Std.is(s, String)) [s];
					else cast s;
				case Failure(_): [];
			}
	}
	@:arrayAccess function get(key:String):Outcome<String, Error> {
		return 
			if (Reflect.hasField(this, key)) Success(Std.string(Reflect.field(this, key)));
			else Failure(Error.make('MISSING_PARAM', 'parameter $key not found', key));
	}
	@:to function toMap():StringMap<String> {
		var ret = new StringMap();
		for (f in Reflect.fields(this))
			ret.set(f, Std.string(Reflect.field(this, f)));
		return ret;
	}	
	
	@:from static function fromString(s:String) 
		return new Values(Runtime.load('querystring').parse(s));
	
}
abstract Path(Array<String>) {
	public var length(get, never):Int;
	public function new(parts:Array<String>) {
		this = [for (part in parts) if (part != null && part != '') part];
	}
	public function after(other:Array<String>) {
		var index = 0;
		for (part in other)
			if (this[index] == part) index++;
			
		return new Path(this.slice(index));
	}
	function get_length() return this.length;
	@:arrayAccess function get(key:Int) return this[key];
	@:to public function toString() {
		return '/'+ this.join('/');//TODO: check whether the leading slash is really good
	}
}
class Request extends InStream {
	//static var urlParse = Runtime.load('url').parse;
	@:read var server:Server = _;
	@:forward var request:NativeRequest = _;
	var response:Dynamic = _;
	@:read var params:Values;
	@:read var path:Path;
	public function getCookies():Map<String, String> {
		var ret = new Map();
		if (request.headers.cookie != null)
			ret.set(for (part in request.headers.cookie.split(';')) {
				var index = part.indexOf('=');
				$(part.substr(0, index).trim(), part.substr(index + 1).trim());
			});
		return ret;
	}
	function new() {
		super(request);
		var parsed:{ pathname:String, query:Dynamic<String> } = Runtime.load('url').parse(request.url, true);
		this.params = new Values(parsed.query);
		this.path = new Path(parsed.pathname.split('/'));
	}
	@:read(request.connection.encrypted) var secure:Bool;
	public function trailers(handler) 
		end.get(function () handler(request.trailers));
	public function setHeader(header:String, value:String) {
		response.setHeader(header, value);
	}
	public function getPostData() 
		return {
			raw: all()
		} => {
			var values:Values = raw.toString();//TODO: I suppose this could fail
			Success(values);
		}
		
	public function respond(?status = 200, ?reason:String, ?headers:Headers) {
		response.writeHead(status, reason, headers);
		return new Response(response);
	}
}
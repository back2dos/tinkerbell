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

enum CookieChange {
	Unset;
	None;
	Set(value:String, ?path:String, ?expires:Date);
}

abstract Cookies(Map<String, { value: String, change: CookieChange }>) {
	inline function new(map) this = map;
	
	@:arrayAccess public function has(id:String) 
		return this[id] != null && this[id].change != Unset;
	
	@:arrayAccess public function get(id:String)
		return 
			if (has(id)) Success(this[id].value);
			else Failure(Error.make('COOKIE_NOT_SET', 'Cookie $id is not set'));

	public function set(id:String, value:String, ?path:String, ?expires:Date) {
		if (value == null)
			remove(id);
			
		this[id] = {
			change: Set(value, path, expires),
			value: value,
		}
	}
	
	public function remove(id:String) 
		return 
			if (has(id)) false;
			else {
				this[id].change = Unset;
				true;
			}
			
	public function toHeaders() {
		var ret = [];
		function add(name:String, value:String, path:String, expires:Date) {
			name = name.urlEncode();
			value = value.urlEncode();
			var s = '$name=$value';
			
			if (path != null) {
				path = path.split('?')[0].split('#')[0];
				s += '; Path=$path';
			}
			if (expires != null)
				s += '; Expires=$expires';
			ret.push(['Set-Cookie', s]);
		}
		
		for (k in this.keys())
			switch this[k].change {
				case None:
				case Unset: 
					add(k, 'none', null, new Date(0,0,0,0,0,0));
				case Set(value, path, expires):
					add(k, value, path, expires);
			}
			
		return ret;
	}
	
	@:from static public function parse(s:String) {
		var ret = new Map();
		if (s != null)
			for (part in s.split(';')) {
				var index = part.indexOf('=');
				ret[part.substr(0, index).trim().urlDecode()] = { 
					value: part.substr(index + 1).trim().urlDecode(),
					change: None,
				}
			};
		
		return new Cookies(ret);
	}
}

class Request extends InStream {
	//static var urlParse = Runtime.load('url').parse;
	@:read var server:Server = _;
	@:forward var request:NativeRequest = _;
	var response:Dynamic = _;
	@:read var params:Values;
	@:read var path:Path;
	@:cache var cookies = Cookies.parse(request.headers.cookie);
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
		var h = cookies.toHeaders();
		
		if (headers != null)
			for (f in Reflect.fields(headers))
				h.push([f, Reflect.field(headers, f)]);
				
		response.writeHead(status, reason, h);
		
		return new Response(response);
	}
}
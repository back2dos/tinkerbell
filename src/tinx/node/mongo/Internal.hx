package tinx.node.mongo;

#if !macro

import haxe.ds.StringMap;
import tink.core.types.*;
import tink.core.types.Signal;
import tink.core.types.Future;

import tink.lang.Cls;
import tinx.node.Error;

@:native("require('mongodb').Db")
extern class NativeDb {
	function collection(name:String, handler:Handler<Dynamic>):Void;
	function close():Void;
	static function connect(url:String, options:Dynamic, handler:Handler<NativeDb>):Void;
}

private typedef NativeCursor<T> = {
	function count(h:Handler<Int>):Void;
	function skip(count:Int, h:Handler<NativeCursor<T>>):Void;
	function limit(count:Int, h:Handler<NativeCursor<T>>):Void;
	function toArray(h:Handler<Array<T>>):Void;
	function each(h:Handler<T>):Void;
}
private typedef NativeCollection<T> = {
	function remove(query:Dynamic, options: { single:Bool }, handler:Handler<tink.core.types.Signal.Noise>):Void;
	function aggregate(pipeline:Array<Dynamic>, handler:Handler<Dynamic>):Void;
	function findOne(match:Dynamic, project:Dynamic, handler:Handler<Dynamic>):Void;
	function find(match:Dynamic, project:Dynamic, handler:Handler<NativeCursor<Dynamic>>):Void;
	function insert(docs:Array<T>, options:Dynamic, handler:Handler<Array<T>>):Void;
	function update(match:Dynamic, update:Dynamic, options:Dynamic, handler:Handler<Noise>):Void;//TODO: it seems that the result is not actually fetched
	function findAndModify(match:Dynamic, sort:Array<Dynamic>, update:Dynamic, options:Dynamic, handler:Handler<Dynamic>):Void;
}
class Cursor<T> implements Cls {
	var native:Unsafe<NativeCursor<T>> = _;
	public function count() 
		return { cursor : native } => cursor.count(_);
		
	public function skip(count) 
		return new Cursor({ cursor : native } => cursor.skip(count, _));
	
	public function limit(count) 
		return new Cursor({ cursor : native } => cursor.limit(count, _));
		
	public function toArray() 
		return { cursor : native } => cursor.toArray(_);
		
	public function each(cb:Callback<T>, ?end:Callback<Outcome<Noise, Error>>)
		{ 
			cursor : native 
		} => {
			cursor.each(new LeftFailingHandler(function (error:Error, obj:T) {
				if (end != null)
					if (error != null) end.invoke(Failure(error));
					else if (obj == null) end.invoke(Success(Noise));
				if (obj != null)
					cb.invoke(obj);
			}));
			true;
		}
}
class CollectionBase<T> implements Cls {
	var native:Unsafe<NativeCollection<T>> = _;
	
	function _findOne<A>(proto:A, match:Dynamic, project:Dynamic):Unsafe<A>
		return 
			{ collection : native } => collection.findOne(match, project, _);			
			
	function _find<A>(proto:A, match:Dynamic, project:Dynamic):Cursor<A>
		return 
			new Cursor( { collection : native } => collection.find(match, project, _));
			
	function _remove(match:Dynamic, justOne:Bool)
		return 
			{ collection : native } => collection.remove(match, { single: justOne }, _);
				
	function _update(match:Dynamic, update:Dynamic, options:Dynamic)
		return 
			{ collection : native } => collection.update(match, update, options, _);
			
	function _findAndModify<A>(proto:A, match:Dynamic, update:Dynamic, options:Dynamic):Unsafe<A>
		return 
			{ collection : native } => collection.findAndModify(match, [], update, options, _);
}

private typedef DbParamObj = { 
	?name: String, 
	?host:String, 
	?port:Int, 
	?login: { user:String, password:String }
}

abstract DbParams(DbParamObj) from DbParamObj to DbParamObj {
	static var wlogin = ~/mongodb:\/\/(.*?):(.*?)@(.*?):(.*?)\/(.*)/;
	static var anon = ~/mongodb:\/\/(.*?):(.*?)\/(.*)/;
	@:from static public function ofString(s:String) {
		return 
			if (wlogin.match(s)) {
				host: wlogin.matched(3),
				name: wlogin.matched(5),
				port: Std.parseInt(wlogin.matched(4)),
				login: {
					user: wlogin.matched(1),
					password: wlogin.matched(2),
				}
			}
			else if (anon.match(s)) {
				host: anon.matched(1),
				name: anon.matched(3),
				port: Std.parseInt(anon.matched(2)),
			}
			else throw 'invalid connector string $s';
	}	
}
class DbBase implements Cls {
	var native:Unsafe<NativeDb>;
	var collections = new StringMap<Collection<Dynamic>>();
	var prefix:String = '';
	@:read var connector:String;
	public function new(?params:DbParams) {
		
		var params:DbParamObj = params;
		if (params == null) params = { };
		
		var name = if (params.name == null) 'test' else params.name,
			host = if (params.host == null) 'localhost' else params.host,
			port = if (params.port == null) 27017 else params.port,
			login = 
				if (params.login == null) '' 
				else (params.login.user + ':' + params.login.password) + '@';
				
		this.native = { db : NativeDb.connect(this.connector = 'mongodb://$login$host:$port/$name', { safe: true }, _) } => db;
	}
	public function close() 
		{ db : native } => { db.close(); true; }
	
	function collection<A>(name:String):Collection<A> {
		if (!collections.exists(name)) 
			collections.set(
				name, 
				new Collection( { db : native } => db.collection(prefix + name, _))
			);
		
		return cast collections.get(name);
	}
}
#else
	class CollectionBase<T> {}
#end
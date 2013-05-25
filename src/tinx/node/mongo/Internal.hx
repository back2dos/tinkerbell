package tinx.node.mongo;

#if !macro

import haxe.ds.StringMap;
import tink.core.types.*;

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
}
private typedef NativeCollection<T> = {
	function remove(query:Dynamic, options: { single:Bool }, handler:Handler<tink.core.types.Signal.Noise>):Void;
	function aggregate(pipeline:Array<Dynamic>, handler:Handler<Dynamic>):Void;
	function findOne(match:Dynamic, project:Dynamic, handler:Handler<Dynamic>):Void;
	function find(match:Dynamic, project:Dynamic, handler:Handler<NativeCursor<Dynamic>>):Void;
	function insert(docs:Array<T>, options:Dynamic, handler:Handler<Array<T>>):Void;
	function update(match:Dynamic, update:Dynamic, options:Dynamic, handler:Handler<Array<T>>):Void;//TODO: it seems that the result is not actually fetched
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
class DbBase implements Cls {
	var native:Unsafe<NativeDb>;
	var collections = new StringMap<Collection<Dynamic>>();
	var prefix:String = ('');
	public function new(_, ?params: { ?name: String, ?host:String, ?port:Int, ?login: { user:String, password:String }} ) {
		if (params == null) params = { };
		var name = if (params.name == null) 'test' else params.name,
			host = if (params.host == null) 'localhost' else params.host,
			port = if (params.port == null) 27017 else params.port,
			login = 
				if (params.login == null) '' 
				else (params.login.user + ':' + params.login.password) + '@';
				
		this.native = { db : NativeDb.connect('mongodb://$login$host:$port/$name', { safe: true }, _) } => db;
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
package tinx.node.mongo;

#if !macro

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
	function aggregate(pipeline:Array<Dynamic>, handler:Handler<Dynamic>):Void;
	function findOne(match:Dynamic, project:Dynamic, handler:Handler<Dynamic>):Void;
	function find(match:Dynamic, project:Dynamic, handler:Handler<NativeCursor<Dynamic>>):Void;
	function insert(docs:Array<T>, options:Dynamic, handler:Handler<Array<T>>):Void;
	function update(match:Dynamic, update:Dynamic, options:Dynamic, handler:Handler<Array<T>>):Void;
	function findAndModify(match:Dynamic, update:Dynamic, options:Dynamic, handler:Handler<Dynamic>):Void;
}
class Cursor<T> implements Cls {
	var native:Unsafe<NativeCursor<T>> = _;
	public function count() 
		return { cursor : native } => cursor.count(_);
		
	public function skip(count) 
		return new Cursor({ cursor : native } => cursor.limit(count, _));
	
	public function limit(count) 
		return new Cursor({ cursor : native } => cursor.skip(count, _));
		
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
			new Cursor({ collection : native } => collection.find(match, project, _));
	
	function _update(match:Dynamic, update:Dynamic, options:Dynamic)
		return 
			{ collection : native } => collection.update(match, update, options, _);
}
class DbBase implements Cls {
	var native:Unsafe<NativeDb>;
	var collections = new Hash<Collection<Dynamic>>();
	
	public function new(?name = 'test', ?host = 'localhost', ?port = 27017, ?login: { user:String, password:String } ) {
		var login = if (login == null) '' else (login.user +':' + login.password);
		this.native = { db : NativeDb.connect('mongodb://$login@$host:$port/$name', { safe: true }, _) } => db;
	}
	public function close() 
		{ db : native } => { db.close(); true; }
	
	function collection<A>(name:String):Collection<A> {
		if (!collections.exists(name)) 
			collections.set(
				name, 
				new Collection({ db : native } => db.collection(name, _))
			);
		
		return cast collections.get(name);
	}
}
#else
	class CollectionBase<T> {}
#end
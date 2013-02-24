package tinx.node.mongo;

#if !macro
import tink.core.types.*;
import tink.lang.Cls;

using tinx.node.Exception;

@:native("require('mongodb').Db")
extern class NativeDb {
	function collection(name:String, handler:Handler<Dynamic>):Void;
	function close():Void;
	static function connect(url:String, options:Dynamic, handler:Handler<NativeDb>):Void;
}

class DbBase implements Cls {
	var native:Unsafe<NativeDb>;
	var collections:Map<StringCollection<Dynamic>>;
	
	public function new(?name = 'test', ?host = 'localhost', ?port = 27017, ?login: { user:String, password:String } ) {
		var login = if (login == null) '' else (login.user +':' + login.password);
		this.native = NativeDb.connect.bind('mongodb://$login@$host:$port/$name', { safe: true } ).future();
		this.collections = new Map();
	}
	public function close() 
		native.handle(function(db) db.close())
	
	function collection<A>(name:String):Collection<A> {
		if (!collections.exists(name)) 
			collections.set(
				name, 
				new Collection(
					native.chain(function (db:NativeDb) return db.collection.bind(name).future())
				)
			);
		
		return cast collections.get(name);
	}
}

private typedef NativeCursor<T> = {
	function count(h:Handler<Int>):Void;
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
		return
			native.chain(function (c) return c.count.future())
	public function toArray() 
		return
			native.chain(function (c) return c.toArray.future())
}
class CollectionBase<T> implements Cls {
	var native:Unsafe<NativeCollection<T>> = _;
	
	function _findOne<A>(proto:A, match:Dynamic, project:Dynamic):Unsafe<A>
		return
			native.chain(function (c) 
				return c.findOne.bind(match, project).future()
			)
			
	function _find<A>(proto:A, match:Dynamic, project:Dynamic):Cursor<A>
		return 
			new Cursor(native.chain(function (c) 
				return c.find.bind(match, project).future()
			))			
	
	function _update(match:Dynamic, update:Dynamic, options:Dynamic)
		return
			native.chain(function (c)
				return c.update.bind(match, update, options).future()
			)
	
	function _aggregate(pipeline) 
		return 
			native.chain(function (c)
				return c.aggregate.bind(pipeline).future()
			)
}
#else
	class CollectionBase<T> {}
#end
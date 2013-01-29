package tinx.node.mongo;

import tinx.node.mongo.Internal;

#if macro
	import haxe.macro.Expr;
	import tinx.node.mongo.lang.Match;
	import tinx.node.mongo.lang.Update;
	import tinx.node.mongo.lang.Projection;
	
	using tinx.node.mongo.lang.Compiler;
	using tinx.node.mongo.lang.TypeInfo;
	using tink.macro.tools.MacroTools;
	using tink.core.types.Outcome;
#else
	using tinx.node.Exception;
#end

class Collection<T> extends CollectionBase<T> {
	#if! macro
		public function insertOne(doc:T):Unsafe<T>
			return insert([doc]).map(function (res) return res[0])
		
		public function insert(docs:Array<T>):Unsafe<Array<T>>
			return
				native.chain(function (c) 
					return c.insert.bind(docs, { safe: true }).future()
				)				
	#end
	macro public function where(ethis:Expr, match:Expr) {
		match = Match.compile(match, ethis.getInfo()).expr;
		return macro new tinx.node.mongo.Collection.Where($ethis, $match);
	}
}

class Where<T> extends CollectionBase<T> {
	#if !macro
		var match:Dynamic;
		public function new(c:Collection<T>, match) {
			super(c.native);
			this.match = match;
		}
		public function remove() {
			
		}
		public function removeAll() {
			
		}
	#else
		static function find(ethis:Expr, func:String, projection:Array<Expr>) {
			var info = ethis.getInfo();
			var projection = Projection.compile(projection, info);
			var proto = projection.type;
			return (macro {
				var tmp = $ethis;
				@:privateAccess tmp.find($proto, tmp.match, ${projection.expr});
			}).finalize({ find: '_' + func });
		}
	#end
	
	macro public function first(ethis:Expr, projection:Array<Expr>) 
		return find(ethis, 'findOne', projection)
	
	macro public function all(ethis:Expr, projection:Array<Expr>) 
		return macro${find(ethis, 'find', projection)}.toArray()
	
	macro public function cursor(ethis:Expr, projection:Array<Expr>) 
		return find(ethis, 'find', projection)
	
	macro public function updateFirst(ethis:Expr, updates:Array<Expr>) 
		return ethis
	
	macro public function updateAll(ethis:Expr, updates:Array<Expr>) 
		return ethis
	
}
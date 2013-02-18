package tinx.node.mongo;

import tinx.node.mongo.Internal;

#if macro
	import haxe.macro.Expr;
	import tinx.node.mongo.lang.Match;
	
	using tinx.node.mongo.lang.Compiler;
	using tinx.node.mongo.lang.TypeInfo;
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
		return macro @:pos(match.pos) new tinx.node.mongo.Where($ethis, $match);
	}
}

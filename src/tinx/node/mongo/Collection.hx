package tinx.node.mongo;

import haxe.macro.Context;
import tink.lang.helpers.CollectorOp;
import tinx.node.mongo.Internal;

#if macro
	import haxe.macro.Expr;
	import tinx.node.mongo.lang.Match;
	
	using tinx.node.mongo.lang.Compiler;
	using tinx.node.mongo.lang.TypeInfo;
#else
	import tinx.node.Error;
#end

class Collection<T> extends CollectionBase<T> {
	#if! macro
		public function insertOne(doc:T):Unsafe<T>
			return { result : insert([doc]) } => CollectorOp.fromAny(result[0]);
		
		public function insert(docs:Array<T>):Unsafe<Array<T>>
			return { collection : native } => collection.insert(docs, { safe: true }, _);
	#end
	macro public function where<T>(ethis:ExprOf<Collection<T>>, ?match:Expr):ExprOf<Where<T>> {
		ethis = macro @:pos(ethis.pos) @:privateAccess $ethis;
		match = Match.compile(match, ethis.getInfo()).expr;
		return macro @:pos(match.pos) new tinx.node.mongo.Where($ethis, $match);
	}
}

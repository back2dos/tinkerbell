package tinx.node.mongo;

import haxe.macro.Context;
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
			return { result : insert([doc]) } => cast result[0];//the cast here is necessary because the compiler is unable to promote Collect.T to surprise
		
		public function insert(docs:Array<T>):Unsafe<Array<T>>
			return { collection : native } => collection.insert(docs, { safe: true }, _);
	#end
	macro public function where<T>(ethis:ExprOf<Collection<T>>, ?match:Expr):ExprOf<Where<T>> {
		ethis = macro @:privateAccess $ethis;
		match = Match.compile(match, ethis.getInfo()).expr;
		return macro @:pos(match.pos) new tinx.node.mongo.Where($ethis, $match);
	}
}

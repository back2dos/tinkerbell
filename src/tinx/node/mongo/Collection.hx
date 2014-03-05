package tinx.node.mongo;

import tink.lang.helpers.CollectorOp;
import tinx.node.mongo.Internal;

#if macro
	import haxe.macro.Context;
	import haxe.macro.Expr;
	import tinx.node.mongo.lang.Match;
	using tink.macro.tools.MacroTools;
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
	macro public function first<T>(ethis:ExprOf<Collection<T>>, projection:Array<Expr>):ExprOf<T> {
		ethis = macro @:privateAccess $ethis;
		return macro @:pos(Context.currentPos()) $ethis.where().first($a { projection } );
	}
	macro public function all<T>(ethis:ExprOf<Collection<T>>, projection:Array<Expr>):ExprOf<T> {
		ethis = macro @:privateAccess $ethis;
		return macro @:pos(Context.currentPos()) $ethis.where().all($a { projection } );
	}
	// macro public function where<T>(ethis:ExprOf<Collection<T>>, ?match:Expr):ExprOf<Where<T>> {
	macro public function where(ethis:Expr, ?match:Expr):Expr {
		ethis = macro @:pos(ethis.pos) @:privateAccess $ethis;
		match = Match.compile(match, ethis.getInfo()).expr;
		return macro @:pos(match.pos) new tinx.node.mongo.Where($ethis, $match);
	}
}

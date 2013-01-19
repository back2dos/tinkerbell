package tink.sql;
import haxe.macro.Context;
import sys.db.Connection;
import tink.core.types.Outcome;
/**
 * ...
 * @author back2dos
 */

class Query<A> {
	var items:List<A>;
	public var error(default, null):Dynamic;
	public function new(cnx:Connection, qry:String) {
		try {
			this.items = cast cnx.request(qry).results();
		}
		catch (e:Dynamic) {
			this.error = e;
		}
	}
	public function get() {
		return
			if (items == null) Failure(error);
			else Success(items);
	}
	public function count() {
		return 
			if (items == null) throw error;
			else items.length;
	}
	public function iterator() {
		return
			if (items == null) throw error;
			else items.iterator();
	}
}
#if macro
	import haxe.macro.Expr;
	import tink.macro.tools.AST;
	import tink.sql.macros.SqlCommands;
	
	using tink.macro.tools.MacroTools;
#end
class SelectRange<T> extends Query<T> {
	#if macro
		static public function make(cnx:Expr, qry:Expr, type:ComplexType):Expr {
			return AST.build(new tink.sql.Query.SelectRange<Eval__type>($cnx, $qry));
		}
	#end	
}
class SelectOrdered<T> extends Query<T> {
	#if macro
		static public function make(cnx:Expr, qry:Expr, type:ComplexType):Expr {
			return AST.build(new tink.sql.Query.SelectOrdered<Eval__type>($cnx, $qry));
		}
	#end		
	macro public function limit(ethis:Expr, count:Int, ?offset:Int) {
		var s:SqlSelect = ethis.untag().data;
		s.range = { count: count, offset:offset }; 
		return SqlCommands.select(s, SelectRange.make).tag(s);
	}
}
class SelectWhere<T> extends SelectOrdered<T> {
	#if macro
		static public function make(cnx:Expr, qry:Expr, type:ComplexType):Expr {
			return AST.build(new tink.sql.Query.SelectWhere<Eval__type>($cnx, $qry));
		}
	#end
	macro public function order(params:Array<Expr>) {
		var s:SqlSelect = params.shift().untag().data;
		if (params.length == 0)
			Context.warning('empty order clause', Context.currentPos());
		s.order = params;
		return SqlCommands.select(s, SelectOrdered.make).tag(s);
	}
}
class Select<T> extends SelectWhere<T> {
	#if macro
		static public function make(cnx:Expr, qry:Expr, type:ComplexType):Expr {
			return AST.build(new tink.sql.Query.Select<Eval__type>($cnx, $qry));
		}
	#end
	macro public function where(params:Array<Expr>) {
		var s:SqlSelect = params.shift().untag().data;
		s.where = params;
		return SqlCommands.select(s, SelectWhere.make).tag(s);
	}
}
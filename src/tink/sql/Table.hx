package tink.sql;

/**
 * ...
 * @author back2dos
 */

#if macro
	import haxe.macro.Context;
	import haxe.macro.Expr;
	import tink.macro.tools.AST;
	import tink.sql.macros.SqlData;	
	import tink.sql.macros.SqlCommands;	
	import tink.sql.Query;
	
	using tink.macro.tools.MacroTools;
	using tink.core.types.Outcome;
#end

//class Join {
	//@:macro public function select(params:Array<Expr>) {
		//var s:SqlSelect = params.shift().untag().data;
		//s.values = params;
		//return 'tink.sql.Query'.asTypePath('Select').partial(s);
	//}
	//@:macro public function join(params:Array<Expr>):Expr {
		//var s:SqlSelect = params.shift().untag().data;
		//s.join.push(params);
		//return 'tink.sql.Table'.asTypePath('Join').partial(s);
	//}
//}


class Table < D:Database, T > {
	public var database(default, null):D;
	public var name(default, null):String;
	public function new(database, name) {
		this.database = database;
		this.name = name;
	}
	//@:macro public function update(ethis:Expr, params:Expr) {
		//return SqlCommands.insert(ethis, params);
	//}
	@:macro public function join(ethis:Expr, other:Expr, ?on:Expr, ?kind:Expr):Expr {
		
		var table = SqlTableDesc.fromExpr(ethis),
			otherName = other.getIdent().sure();
		
		if (!table.db.has(otherName))
			other.reject('unknown table ' + otherName);
			
		
			
		return ethis;
	}

	@:macro public function select(params:Array<Expr>):Expr {
		var table = params.shift();
		var s:SqlSelect = { from: { expr: table, desc: SqlTableDesc.fromExpr(table) }, join: [], values:params };
		return SqlCommands.select(s, Select.make).tag(s);
	}
	@:macro public function insert(ethis:Expr, params:Expr) {
		return SqlCommands.insert(ethis, params);
	}
}
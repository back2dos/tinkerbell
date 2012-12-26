package tink.sql;

#if macro
	import haxe.macro.Context;
	import haxe.macro.Expr;
	import tink.macro.tools.AST;
	import tink.sql.macros.SqlBuilder;
	import tink.sql.macros.SqlData;	
	import tink.sql.macros.SqlCommands;	
	import tink.sql.Query;
	
	using tink.macro.tools.MacroTools;
	using tink.core.types.Outcome;
#end

class Join {
	@:macro public function select(params:Array<Expr>) {
		var s:SqlSelect = params.shift().untag().data;
		s.values = SqlBuilder.selectClause(params, s.ctx);
		return SqlCommands.select(s, Select.make).tag(s);
	}
	@:macro public function join(ejoin:Expr, other:Expr, ?kind:Expr, ?on:Expr):Expr {
		var s:SqlSelect = ejoin.untag().data;
		s.ctx.join(other, kind, on);
		return 'tink.sql.Table.Join'.asComplexType().partial(s);
	}
}


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
	@:macro public function join(ethis:Expr, other:Expr, ?kind:Expr, ?on:Expr):Expr {
		var ctx = SqlContext.from(ethis);
		ctx.join(other, kind, on);
		var s:SqlSelect = { from: { expr: ethis, desc: ctx.first }, ctx: ctx };
		return 'tink.sql.Table.Join'.asComplexType().partial(s);
	}

	@:macro public function select(params:Array<Expr>):Expr {
		var table = params.shift();
		var ctx = SqlContext.from(table);
		var s:SqlSelect = { from: { expr: table, desc: ctx.first }, ctx: ctx, values:SqlBuilder.selectClause(params, ctx) };
		
		return SqlCommands.select(s, Select.make).tag(s);		
	}
	@:macro public function insert(ethis:Expr, params:Expr) {
		return SqlCommands.insert(ethis, params);
	}
}
package tink.sql;

/**
 * ...
 * @author back2dos
 */

#if macro
	import haxe.macro.Expr;
	import tink.sql.macros.SqlCommands;	
	
	using tink.macro.tools.MacroTools;
#end

class Join {
	@:macro public function select(params:Array<Expr>) {
		var s:SqlSelect = params.shift().untag().data;
		s.values = params;
		return 'tink.sql.Table'.asTypePath('Select').partial(s);
	}
	@:macro public function join(params:Array<Expr>):Expr {
		var s:SqlSelect = params.shift().untag().data;
		s.join.push(params);
		return 'tink.sql.Table'.asTypePath('Join').partial(s);
	}	
}

class SelectWhere {
	@:macro public function get(params:Array<Expr>) {
		var s:SqlSelect = params.shift().untag().data;
		s.options = params;
		return SqlCommands.select(s);
	}	
}

class Select extends SelectWhere {
	@:macro public function where(params:Array<Expr>) {
		var s:SqlSelect = params.shift().untag().data;
		s.where = params;
		return 'tink.sql.Table'.asTypePath('SelectWhere').partial(s);
	}
}

class Table < D:Database, T > {
	public var database(default, null):D;
	public var name(default, null):String;
	public function new(database, name) {
		this.database = database;
		this.name = name;
	}
	@:macro public function join(params:Array<Expr>):Expr {
		var t = params.shift();
		var s:SqlSelect = { from: t, join:[params] };
		return 'tink.sql.Table'.asTypePath('Join').partial(s);
	}
	@:macro public function select(params:Array<Expr>):Expr {
		var t = params.shift();
		var s:SqlSelect = { from: t, join: [], values:params };
		return 'tink.sql.Table'.asTypePath('Select').partial(s);
	}
	@:macro public function insert(ethis:Expr, params:Expr) {
		return SqlCommands.insert(ethis, params);
	}
}
package tink.sql.macros;

private typedef Enums = Type;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
using tink.sql.macros.SqlBuilder;
/**
 * ...
 * @author back2dos
 */

enum SqlBinop {
	@comparison @translate('=', 'OpEq') SqlEq;
	@comparison @translate('<>', 'OpNotEq') SqlNeq;
	@comparison @translate('<', 'OpLt') SqlLt;
	@comparison @translate('<=', 'OpLte') SqlLte;
	@comparison @translate('>', 'OpGt') SqlGt;
	@comparison @translate('>=', 'OpGte') SqlGte;

	@arithmetic @translate('+', 'OpAdd') SqlAdd;
	@arithmetic @translate('-', 'OpSub') SqlSub;
	@arithmetic @translate('*', 'OpMult') SqlMult;
	@arithmetic @translate('/', 'OpDiv') SqlDiv;
	
	@logic @translate('AND', 'OpAnd') SqlAnd;
	@logic @translate('OR', 'OpOr') SqlOr;
}
typedef SqlExpr = {
	pos:Position,
	expr:SqlEDef,
	type:Type
}

enum SqlEDef {
	SqlAlias(name:String, of:SqlExpr);
	SqlField(name:String, ?table:String);
	SqlParam(e:Expr);
	SqlIn(e:SqlExpr, options:Array<SqlExpr>);
	SqlBin(op:SqlBinop, e1:SqlExpr, e2:SqlExpr);
} 
class SqlDatabaseDesc {
	var tables:Map<StringSqlTableDesc>;
	var type:Type;
	function new(type:Type) {
		this.type = type;
	}
	function init() {
		if (tables == null) {
			tables = new Map();	
			for (f in type.getFields().sure()) 
				if (f.type.getID() == 'tink.sql.Table') 
					this.tables.set(f.name, SqlTableDesc.get(f.type, f.pos));
		}		
	}
	public function has(name:String) {
		init();
		return tables.exists(name);
	}
	public function table(name:String) {
		init();
		return tables.get(name);
	}
	static var cache = new Map<StringSqlDatabaseDesc>();	
	static public function get(type:Type):SqlDatabaseDesc {
		var key = Context.signature(type);
		var ret = cache.get(key);
		if (ret == null)
			cache.set(key, ret = new SqlDatabaseDesc(type));
		return ret;
	}		
}
class SqlTableDesc {
	public var name(default, null):String;
	public var db(default, null):SqlDatabaseDesc;
	
	var fieldMap:Map<StringClassField>;
	var fieldList:Array<ClassField>;
	
	public var type(default, null):Type;
	public var cType(default, null):ComplexType;
	
	function new(db:Type, tb:ClassField) { 
		
		this.name = tb.name;
		this.type = tb.type;
		this.cType = tb.type.toComplex();
		this.fieldList = tb.type.getFields().sure();
		this.fieldMap = new Map();
		
		for (f in this.fieldList)
			this.fieldMap.set(f.name, f);
		
		this.db = SqlDatabaseDesc.get(db);
	}
	public inline function hasField(name:String) {
		return fieldMap.exists(name);
	}
	public inline function field(name:String) {
		return fieldMap.get(name);
	}
	public inline function fields() {
		return fieldList.iterator();
	}
	static var cache = new Map<StringSqlTableDesc>();
	static public function get(type:Type, pos:Position):SqlTableDesc {
		return
			switch (type) {
				case TInst(_, params): 
					var cf = params[1].getFields().sure()[0];
					var key = Context.signature(cf);//we have to dig down to this classfield to get a unique signature
					var ret = cache.get(key);
					if (ret == null)
						cache.set(key, ret = new SqlTableDesc(params[0], cf));
					ret;
				default: 
					pos.error('assert failed');
			}
	}
	static public function fromExpr(e:Expr) {
		return get(e.typeof().sure(), e.pos);
	}
}
enum SqlJoinKind {
	LEFT;
	RIGHT;
	INNER;
	NATURAL;
}
typedef SqlJoin = {
	cond:SqlExpr,
	kind:SqlJoinKind,
	table:SqlTableDesc
}
class SqlContext {
	public var first(default, null):SqlTableDesc;
	var joins:Array<SqlJoin>;
	var tableMap:Map<StringSqlTableDesc>;
	public function new(first:SqlTableDesc) {
		this.first = first;
		this.tableMap = new Map();
		this.tableMap.set(first.name, first);
		this.joins = [];
	}
	public function has(name:String) {
		return tableMap.exists(name);
	}
	public function table(name:String) {
		return tableMap.get(name);
	}
	public function join(table:Expr, kind:Expr, on:Expr) {
		var tName = table.getIdent().sure();
		if (!first.db.has(tName))
			table.reject('unknown table ' + tName);		
		var table = first.db.table(tName);
		var kindName = kind.ifNull('natural'.resolve()).getIdent().sure().toUpperCase();
		var kind =
			if (Enums.getEnumConstructs(SqlJoinKind).copy().remove(kindName))
				Enums.createEnum(SqlJoinKind, kindName);
			else
				kind.reject('unknown join type ' + kindName);
		tableMap.set(tName, table);
		joins.push( {
			cond: on.ifNull(1.toExpr()).toSqlExpr(this),
			table: table,
			kind: kind
		});
	}
	public function joinClause(cnx:Expr, buf:Expr):Expr {
		var ret = [];
		
		return ret.toBlock();
	}
	static public function from(table:Expr) {
		var tDesc = SqlTableDesc.fromExpr(table);
		var ret = new SqlContext(tDesc);
		return ret;
	}
}
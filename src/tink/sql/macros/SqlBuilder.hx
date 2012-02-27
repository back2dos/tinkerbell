package tink.sql.macros;

typedef Enums = Type;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.rtti.Meta;
import tink.macro.tools.AST;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
using Lambda;
/**
 * ...
 * @author back2dos
 */

enum SqlBinop {
	@translate('=', 'OpEq') SqlEq;
	@translate('<>', 'OpNotEq') SqlNeq;
	@translate('+', 'OpAdd') SqlAdd;
	@translate('-', 'OpSub') SqlSub;
	@translate('*', 'OpMult') SqlMult;
	@translate('/', 'OpDiv') SqlDiv;
	@translate('<', 'OpLt') SqlLt;
	@translate('<=', 'OpLte') SqlLte;
	@translate('>', 'OpGt') SqlGt;
	@translate('>=', 'OpGte') SqlGte;
	@translate('AND', 'OpAnd') SqlAnd;
	@translate('OR', 'OpOr') SqlOr;
}
typedef SqlExpr = {
	pos:Position,
	expr:SqlEDef
}

enum SqlEDef {
	SqlField(name:String, ?table:String);
	SqlParam(e:Expr);
	SqlIn(e:SqlExpr, options:Array<SqlExpr>);
	SqlBin(op:SqlBinop, e1:SqlExpr, e2:SqlExpr);
} 

class SqlBuilder {
	static var hx2sql:Hash<SqlBinop>; 
	static var sql2string:Hash<String>;
	static function __init__() {
		var m = Meta.getFields(SqlBinop);
		hx2sql = new Hash();
		sql2string = new Hash();
		for (f in Reflect.fields(m)) {
			var a:Array<String> = Reflect.field(m, f).translate;
			hx2sql.set(a[1], Enums.createEnum(SqlBinop, f));
			sql2string.set(f, a[0]);
		}
	}
	static public function fieldMap(t:Type) {
		return t.getFields().data().fold(function (f, h:Hash<ClassField>) { h.set(f.name, f); return h; }, new Hash());
	}
	static public function describeTable(table:Expr) {
		return 
			switch (table.typeof().data()) {
				case TInst(_, params): 
					var t = params[1].getFields().data()[0];
					{ db: params[0], tableName: t.name, tableType: t.type };
				default: 
					table.reject();
			}
	}
	static public function whereClause(exprs:Array<Expr>):SqlExpr { 
		return
			if (exprs == null || exprs.length == 0) { expr: SqlParam(1.toExpr()), pos:Context.currentPos() };
			else {
				var ret = exprs.shift();
				for (e in exprs)
					ret = ret.binOp(e, OpAnd, e.pos);
				toSqlExpr(ret);
			}
	}
	static public function toSqlExpr(e:Expr):SqlExpr {
		var ret = 
			if (e.typeof().isSuccess()) SqlParam(e);
			else 
				switch (e.getIdent()) {
					case Success(s): SqlField(s);
					default: 
						switch (e.expr) {
							case EBinop(op, e1, e2):
								var name = Enums.enumConstructor(op);
								if (hx2sql.exists(name)) 
									SqlBin(hx2sql.get(name), toSqlExpr(e1), toSqlExpr(e2));
								else
									e.reject('no sql counter-part for ' + op);
							case EIn(e1, e2):
								switch (e2.expr) {
									case EArrayDecl(values):
										var es = [];
										for (v in values)
											es.push(toSqlExpr(v));
										SqlIn(toSqlExpr(e1), es);
									default: 
										//TODO: lift this constraint. In fact the argument only needs to be iterable
										e2.reject('second argument to `in`-clause must be an array literal');
								}
							default: e.reject();
						}
				}
		return { expr: ret, pos:e.pos };
	}
	static public function toSqlString(e:SqlExpr, cnx:Expr, buf:Expr):Expr {
		var ret = [];
		
		function plain(buf, s:String) {
			ret.push(AST.build($buf.add("eval__s")));
		}
			
		function esc(cnx, buf, e:Expr) {
			ret.push(AST.build($cnx.addValue($buf, $e)));
		}
			
		buildSql(e, callback(plain, buf), callback(esc, cnx, buf));
		
		return ret.toBlock(e.pos);
	}
	static public function buildSql(e:SqlExpr, plain:String->Void, esc:Expr->Void) {
		function rec(e)
			buildSql(e, plain, esc);
			
		switch (e.expr) {
			case SqlField(name, table):
				if (table == null) plain(name);
				else plain(table + '.' + name);
			case SqlParam(e): esc(e);
			case SqlIn(e, options):
				plain('(');
				rec(e);
				plain(' IN (');
				for (o in options) rec(o);
				plain('))');
			case SqlBin(op, e1, e2):
				plain('(');
				rec(e1);
				plain(' ' + sql2string.get(Enums.enumConstructor(op)) + ' ');
				rec(e2);
				plain(')');
		}
	}
}
package tink.sql.macros;

private typedef Enums = Type;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.rtti.Meta;
import tink.macro.tools.AST;

import tink.sql.macros.SqlData;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
using Lambda;
/**
 * ...
 * @author back2dos
 */


class SqlBuilder {
	static var hx2sql:Map<StringSqlBinop>; 
	static var sql2string:Map<StringString>;
	static function __init__() {
		var m = Meta.getFields(SqlBinop);
		hx2sql = new Map();
		sql2string = new Map();
		for (f in Reflect.fields(m)) {
			var a:Array<String> = Reflect.field(m, f).translate;
			hx2sql.set(a[1], Enums.createEnum(SqlBinop, f));
			sql2string.set(f, a[0]);
		}
	}
	static public function selectClause(exprs:Array<Expr>, ctx:SqlContext) {
		var ret:Array<{name:String, expr:SqlExpr, ?from:String }> = [];
		for (e in exprs) {
			var sql = toSqlExpr(e, ctx);
			var name = 
				switch (sql.expr) {
					case SqlField(name, table): ret.push( { name: name, expr:sql, from: table } );
					case SqlAlias(name, _): ret.push( { name: name, expr:sql } );
					default: sql.pos.error('only plain fields can be selected for now');
				}
		}
		return ret;
	}
	static public function whereClause(exprs:Array<Expr>, ctx:SqlContext):SqlExpr { 
		return
			if (exprs == null || exprs.length == 0) { expr: SqlParam(1.toExpr()), pos:Context.currentPos(), type: true.toExpr().typeof().sure() };
			else {
				var ret = exprs.shift();
				for (e in exprs)
					ret = ret.binOp(e, OpAnd, e.pos);
				toSqlExpr(ret, ctx);
			}	
	}
	static public function toSqlExpr(e:Expr, ctx:SqlContext):SqlExpr {
		function rec(x) 
			return toSqlExpr(x, ctx);
		function make(x, t):SqlExpr
			return { expr: x, type:t, pos: e.pos };
			
		return
			if (e == null) null;
			else switch (e.typeof()) {
				case Success(t): make(SqlParam(e), t);
				case Failure(f):
					switch (e.getIdent()) {
						case Success(s): 
							if (s.charAt(0) == '$') {
								var name = s.substr(1);
								if (ctx.first.hasField(name))
									make(SqlField(name), ctx.first.field(name).type);
								else
									e.reject('unknown field ' + name);
							}
							else 
								f.throwSelf();
						default: 
							switch (e.expr) {
								case EDisplay(e, _): rec(e);
								case EBinop(op, e1, e2):
									var name = Enums.enumConstructor(op);
									if (hx2sql.exists(name)) {
										var e1 = rec(e1),
											e2 = rec(e2);
										make(SqlBin(hx2sql.get(name), e1, e2), null);
									}
									else
										e.reject('no sql counter-part for ' + op);
								case EIn(e1, e2):
									switch (e2.expr) {
										case EArrayDecl(values):
											var es = [];
											for (v in values)
												es.push(rec(v));
											make(SqlIn(rec(e1), es), null);
										default: 
											//TODO: lift this constraint. In fact the argument only needs to be iterable
											e2.reject('second argument to `in`-clause must be an array literal');
									}
								case EField(owner, field), EType(owner, field):
									switch (owner.getIdent()) {
										case Success(s):
											if (s.charAt(0) == '$') {
												var tName = s.substr(1);
												if (ctx.has(tName)) {
													var table = ctx.table(tName);
													if (table.hasField(field))
														make(SqlField(field, tName), table.field(field).type);
													else
														e.reject('table ' + tName + ' has no field ' + field);
												}
												else
													owner.reject('unknown table ' + tName);
											}
											else
												f.throwSelf();
										default: 
											f.throwSelf();
									}
								default: 
									e.reject();
							}
					}
			}
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
			case SqlAlias(name, of):
				rec(of);
				plain(' AS ' + name);
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
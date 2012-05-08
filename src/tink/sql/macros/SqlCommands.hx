package tink.sql.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import tink.macro.tools.AST;
import tink.sql.macros.SqlData;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
using tink.sql.macros.SqlBuilder;

/**
 * ...
 * @author back2dos
 */

typedef SqlSelect = {
	from:{ expr:Expr, desc:SqlTableDesc },
	ctx:SqlContext,
	?values:Array<{ name:String, ?from:String, expr:SqlExpr }>,
	?where:Array<Expr>,
	?order:Array<Expr>,
	?range:{ count:Int, offset:Null<Int> }
}

class SqlCommands {
	static public function select(cmd:SqlSelect, maker:Expr->Expr->ComplexType->Expr):Expr {
		//if (cmd.join.length > 0)
			//Context.currentPos().error('joins not implemented yet');
		
		var table = cmd.from.desc,
			ctx = cmd.ctx;
			
		var cnx = String.tempName(),
			buf = String.tempName();
		
		var ret = [
			cnx.define(AST.build($(cmd.from.expr).database.cnx)),
			buf.define(AST.build(new StringBuf())),
		];
		
		var cnx = cnx.resolve(),
			buf = buf.resolve();
		
		function out(s:String) 
			ret.push(buf.field('add').call([s.toExpr()]));
		
		out('SELECT ');
		var retType = 
			if (cmd.values == null || cmd.values.length == 0) {
				out('*');
				table.cType;
			}
			else {
				var first = true;
				var fields = [];
				for (v in cmd.values) {
					if (first) first = false;
					else out(', ');
					//var sql = v.toSqlExpr(ctx);
					//var fieldName = getName(sql, ctx);
					fields.push( { name: v.name, doc:null, access:[], kind:FVar(v.expr.type.toComplex()), pos: v.expr.pos, meta: [] } );
					ret.push(v.expr.toSqlString(cnx, buf));
				}
				ComplexType.TAnonymous(fields);
			}
			
		out(' FROM ' + table.name);	
		out(' WHERE ');
		ret.push(cmd.where.whereClause(ctx).toSqlString(cnx, buf));
		
		ret.push(maker(cnx, AST.build($buf.toString()), retType));
		return ret.toBlock().log();
	}
	static public function insert(table:Expr, params:Expr):Expr {
		var info = SqlTableDesc.fromExpr(table);
			
		var given = params.typeof().sure().getFields().sure();
		
		var fieldList = [],
			valueList = [],
			src = String.tempName().resolve();
		
		for (g in given) {
			if (!info.hasField(g.name))
				params.pos.error('table ' + info.name + ' has no field ' + g.name);
			else {
				var k = info.field(g.name);
				switch (g.type.isSubTypeOf(k.type, params.pos)) {
					case Success(_):
						var name = g.name;
						fieldList.push(name.toExpr());
						valueList.push(src.field(name));
					case Failure(f):
						f.pos.error('Error for field ' + g.name + ': ' + f.data);
				}
			}
		}
		var fieldList = EArrayDecl(fieldList).at(),
			valueList = EArrayDecl(valueList).at();
			
		return [
			src.getIdent().sure().define(params),
			AST.build($table.database.insert('eval__tName', $fieldList, $valueList)) 
		].toBlock();
	}
	
	static public function update(table:Expr, params:Expr) {
		
	}
}
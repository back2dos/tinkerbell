package tink.sql.macros;

import haxe.macro.Expr;
import haxe.macro.Type;
import tink.macro.tools.AST;
import tink.sql.macros.SqlBuilder;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
using tink.sql.macros.SqlBuilder;

/**
 * ...
 * @author back2dos
 */

typedef SqlSelect = {
	from:Expr,
	join:Array<Array<Expr>>,
	?values:Array<Expr>,
	?where:Array<Expr>,
	?options:Array<Expr>,
}

class SqlCommands {
	static public function select(cmd:SqlSelect):Expr {
		if (cmd.join.length > 0)
			cmd.join[0][0].pos.error('joins not implemented yet');
		
		var info = cmd.from.describeTable();
		
		var cnx = String.tempName(),
			buf = String.tempName();
		
		var ret = [
			cnx.define(AST.build($(cmd.from).database.cnx)),
			buf.define(AST.build(new StringBuf())),
		];
		
		var cnx = cnx.resolve(),
			buf = buf.resolve();
		
		function out(s:String) 
			ret.push(buf.field('add').call([s.toExpr()]));
		
		out('SELECT ');
		if (cmd.values == null) out('*') 
		else {
			var first = true;
			for (v in cmd.values) {
				if (first) first = false;
				else out(', ');
				var sql = v.toSqlExpr();
				//TODO: type check!
				ret.push(sql.toSqlString(cnx, buf));
			}
		}
		out(' FROM '+info.tableName);	
		out(' WHERE ');
		ret.push(cmd.where.whereClause().toSqlString(cnx, buf));
		ret.push(AST.build($buf.toString()));
			
		return ret.toBlock();
	}
	static public function insert(table:Expr, params:Expr):Expr {
		var pType = params.typeof().data(),
			info = table.describeTable();
		var given = pType.fieldMap(),
			known = info.tableType.fieldMap(),
			tName = info.tableName;
		
		var fieldList = [],
			valueList = [],
			src = String.tempName().resolve();
		
		for (g in given) {
			if (!known.exists(g.name))
				params.pos.error('table ' + tName + ' has no field ' + g.name);
			else {
				var k = known.get(g.name);
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
			src.getIdent().data().define(params),
			AST.build($table.database.insert('eval__tName', $fieldList, $valueList)) 
		].toBlock();
	}
}
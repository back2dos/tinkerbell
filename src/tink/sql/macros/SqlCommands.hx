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
	join:Array<SqlJoin>,
	?values:Array<Expr>,
	?where:Array<Expr>,
	?order:Array<Expr>,
	?range:{ count:Int, offset:Null<Int> }
}

typedef SqlJoin = {
	
}

class SqlCommands {
	static function getType(s:SqlExpr, table:SqlTableDesc):Type {
		return
			switch (s.expr) {
				case SqlField(name, tName):
					if (tName != null) s.pos.error('not implemented');
					if (table.hasField(name)) 
						table.field(name).type;
					else s.pos.error('unknown field ' + name);
					
				case SqlParam(e): 
					e.typeof().sure();
				case SqlIn(_, _): 
					s.pos.error('not implemented');
				case SqlBin(op, e1, e2):
					s.pos.error('not implemented');
			}	
	}
	static function getName(s:SqlExpr, table:SqlTableDesc) {
		return
			switch (s.expr) {
				case SqlField(name, _): name;
				default: s.pos.error('only plain fields can be selected for now');
			}
	}
	static function getTypeAndName(s:SqlExpr, table:SqlTableDesc) {
		return {
			type: getType(s, table),
			name: getName(s, table)
		};
	}
	static public function select(cmd:SqlSelect, maker:Expr->Expr->ComplexType->Expr):Expr {
		if (cmd.join.length > 0)
			cmd.join[0][0].pos.error('joins not implemented yet');
		
		var desc = cmd.from.desc,
			joiners = new Hash();//TODO: cleanup
			
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
				desc.cType;
			}
			else {
				var first = true;
				var fields = [];
				for (v in cmd.values) {
					if (first) first = false;
					else out(', ');
					var sql = v.toSqlExpr(desc, joiners);
					var field = getTypeAndName(sql, desc);
					fields.push( { name: field.name, doc:null, access:[], kind:FVar(field.type.toComplex()), pos: v.pos, meta: [] } );
					ret.push(sql.toSqlString(cnx, buf));
				}
				ComplexType.TAnonymous(fields);
			}
			
		out(' FROM ' + desc.name);	
		out(' WHERE ');
		ret.push(cmd.where.whereClause(desc).toSqlString(cnx, buf));
		
		ret.push(maker(cnx, AST.build($buf.toString()), retType));
		return ret.toBlock();
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
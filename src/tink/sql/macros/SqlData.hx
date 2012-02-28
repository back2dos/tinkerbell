package tink.sql.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

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
	SqlField(name:String, ?table:String);
	SqlParam(e:Expr);
	SqlIn(e:SqlExpr, options:Array<SqlExpr>);
	SqlBin(op:SqlBinop, e1:SqlExpr, e2:SqlExpr);
} 
class SqlDatabaseDesc {
	var tables:Hash<SqlTableDesc>;
	var type:Type;
	function new(type:Type) {
		this.type = type;
	}
	private function init() {
		if (tables == null) {
			tables = new Hash();	
			for (f in type.getFields().sure()) 
				if (f.type.getID() == 'tink.sql.Table') {
					trace('found ' + f.name);
					this.tables.set(f.name, SqlTableDesc.get(f.type, f.pos));
				}
			for (t in this.tables)
				trace('table ' + t.name);
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
	static var cache = new Hash<SqlDatabaseDesc>();	
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
	
	var fieldMap:Hash<ClassField>;
	var fieldList:Array<ClassField>;
	
	public var type(default, null):Type;
	public var cType(default, null):ComplexType;
	
	function new(db:Type, tb:ClassField) { 
		
		this.name = tb.name;
		trace('building info for ' + tb.name);
		this.type = tb.type;
		this.cType = tb.type.toComplex();
		this.fieldList = tb.type.getFields().sure();
		this.fieldMap = new Hash();
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
	static var cache = new Hash<SqlTableDesc>();
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
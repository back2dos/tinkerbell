package tinx.node.mongo.lang;

import haxe.macro.Expr;
import haxe.macro.Type;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

class TypeInfo {
	var fields:Map<StringTypeInfo>;
	public var t(default, null):Type;
	var pos:Position;
	var ct:ComplexType;
	function new(t, pos, ?nonRoot) {
		this.t = t;
		this.ct = t.toComplex();
		this.pos = pos;
		function reject()
			pos.error('type $t not supported by MongoDB');
		
		this.fields = new Map();
		
		switch (t.reduce()) {
			case TAnonymous(_):
				this.fields = t.getFields().map(function (fields:Array<ClassField>) {
					var ret = new Map();
					for (f in fields)
						ret.set(f.name, new TypeInfo(f.type, pos, true));
					return ret;
				}).orUse(null);
			case TAbstract(t, _) if (nonRoot):
				switch (t.toString()) {
					case 'Int', 'Float', 'Bool':
					default: reject();
				}
			case TInst(t, params) if (nonRoot):
				switch (t.toString()) {
					case 'Date', 'String':
					case 'Array': fields.set('[]', new TypeInfo(params[0], pos, true));
					default: reject();
				}
			case other: 
				if (nonRoot) 
					reject();
				else 
					pos.error('type $other not supported for collections');
		}
	}
	//public function has(name) 
		//return fields == null || fields.exists(name)
	
	public function isArray()
		return fields.exists('[]')
	
	public function blank(?pos) 
		return ECheckType(macro null, ct).at(pos == null ? this.pos : pos)
	
	public function get(name, pos:Position) 
		return
			if (fields.exists(name)) 
				fields.get(name)
			else 
				pos.error('unknown field $name')
		
	public function resolve(path:Path) {
		var ret = blank(path.first.pos);
		for (p in path)
			ret = ret.field(p.s, p.pos);
		return ret;
	}
	public function check(path:Path, value:Null<Expr>) {
		if (value == null) 
			throw 'NI';
		else 
			ECheckType(value, resolve(path).lazyType()).at(path.last.pos).typeof().sure();
	}
	static public function getInfo(e:Expr) {
		return 
			switch (e.typeof().sure().reduce()) {
				case TInst(_, params): new TypeInfo(params[0], e.pos);
				default: throw 'assert';
			}
	}	
}
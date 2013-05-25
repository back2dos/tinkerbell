package tinx.node.mongo.lang;

import haxe.ds.StringMap;
import haxe.macro.Expr;
import haxe.macro.Type;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

class TypeInfo {
	var fields:StringMap<TypeInfo>;
	public var t(default, null):Type;
	public var pos(default, null):Position;
	var ct:ComplexType;
	function new(t, pos, ?nonRoot) {
		this.t = t;
		this.ct = t.toComplex();
		this.pos = pos;
		function reject()
			pos.error('type $t not supported by MongoDB');
		
		this.fields = new StringMap();
		
		switch (t.reduce()) {
			case TAnonymous(_), TMono(_), TDynamic(_):
				this.fields = t.getFields().map(function (fields:Array<ClassField>) {
					var ret = new Map();
					for (f in fields)
						ret.set(f.name, new TypeInfo(f.type, pos, true));
					return ret;
				}).orUse(null);
			case TAbstract(t, _) if (nonRoot):
				switch (t.toString()) {
					case 'Int', 'Float', 'Bool':
					default: 
					if (t.get().meta.has(':equiv')) {}
					else reject();
				}
			case TInst(t, params) if (nonRoot):
				switch (t.toString()) {
					case 'Date', 'String', 'tinx.node.mongo.ObjectID':
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
	public function getFields()
		return fields.keys();
		
	public function has(name) 
		return fields == null || fields.exists(name);
	
	public function isArray()
		return fields.exists('[]');
	
	public function blank(?pos) 
		return ECheckType(macro null, ct).at(pos == null ? this.pos : pos);
	
	public function get(name, pos:Position) 
		return
			if (fields == null)
				new TypeInfo((macro null).typeof().sure(), pos, true)
			else if (fields.exists(name)) 
				fields.get(name)
			else 
				pos.error('unknown field $name');
		
	public function resolve(path:Path) {
		var ret = this;
		for (p in path)
			ret = ret.get(p.s, p.pos);
		return ret;
	}
	public function check(path:Path, value:Null<Expr>) {
		if (value == null) 
			throw 'NI';
		else 
			ECheckType(value, resolve(path).blank(path.getPos(this.pos)).lazyType()).at(path.getPos(this.pos)).typeof().sure();
	}
	static public function getInfo(e:Expr) {
		return 
			switch (e.typeof().sure().reduce()) {
				case TInst(_, params): new TypeInfo(params[0], e.pos);
				case TMono(_): new TypeInfo((macro { } ).typeof().sure(), e.pos);
				default: throw (e.typeof());
			}
	}	
}
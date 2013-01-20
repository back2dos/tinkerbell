package tink.macro.build;
 
import haxe.macro.Expr;
import haxe.macro.Printer;
import tink.core.types.Outcome;

using Lambda;
using tink.macro.tools.MacroTools;

typedef Meta = { 
	name : String,
	params : Array<Expr>, 
	pos : Position 
};

class Member {
	public var name : String;
	public var doc : Null<String>;
	public var kind : FieldType;
	public var pos : Position;
	var meta:Hash<Array<Meta>>;
	
	public var isOverride:Bool;
	public var isStatic:Bool;
	///indicates whether the field is inline (true) or dynamic (false) or none of both (null)
	public var isBound:Null<Bool>;
	public var isPublic:Null<Bool>;
	public var excluded:Bool;
	
	public function new() {
		this.isOverride = this.isStatic = false;
		this.meta = new Hash();
		this.excluded = false;
	}
	public inline function forceInline() {
		this.isBound = true;
		addMeta(':extern', pos);
	}
	public inline function publish() {
		if (isPublic == null) 
			isPublic = true;
	}
	public function addMeta(name, pos, ?params) {
		if (!meta.exists(name))
			meta.set(name, []);
		meta.get(name).push({
			name: name,
			pos: pos,
			params: if (params == null) [] else params
		});
	}
	public function disallowMeta(id:String, master:String) {
		if (meta.exists(id))
			meta.get(id)[0].pos.error('cannot use tag ' + id + ' if ' + master + ' is used');
	}
	public function extractMeta(name) {
		return
			if (meta.exists(name)) {
				var ret = meta.get(name);
				if (ret.length == 1)
					meta.remove(name);
				return Success(ret.shift());
			}
			else return Failure();
	}
	public function toString() 
		return new Printer().printField(this.toHaxe())
	
	public function toHaxe():Field {
		return {
			name : name,
			doc : doc,
			access : haxeAccess(),
			kind : kind,
			pos : pos,
			meta : {
				var res = [];
				for (tags in meta)
					for (tag in tags)
						res.push(tag);
				res;
			}
		}
	}
	public function getFunction() {
		return
			switch (kind) {
				case FFun(f): Success(f);
				default: pos.makeFailure('not a function');
			}
	}
	function haxeAccess():Array<Access> {
		var ret = [];
		switch (isPublic) {
			case true: ret.push(APublic);
			case false: ret.push(APrivate);
		}
		switch (isBound) {
			case true: ret.push(AInline);
			case false: ret.push(ADynamic);
		}
		if (isOverride) ret.push(AOverride);
		if (isStatic) ret.push(AStatic);
		return ret;
	}
	static public function prop(name:String, t:ComplexType, pos, ?noread = false, ?nowrite = false) {
		var ret = new Member();
		ret.name = name;
		ret.publish();
		ret.pos = pos;
		ret.kind = FProp(noread ? 'null' : 'get_' + name, nowrite ? 'null' : ('set_' + name), t);
		return ret;
	}
	static public function getter(field:String, ?pos, e:Expr, ?t:ComplexType) {
		return method('get_' + field, pos, false, e.func(t));
	}
	static public function setter(field:String, ?param = 'param', ?pos, e:Expr, ?t:ComplexType) {
		return method('set_' + field, pos, false, [e, param.resolve(pos)].toBlock(pos).func([param.toArg(t)], t));
	}
	static public function method(name:String, ?pos, ?isPublic = true, f:Function) {
		var ret = new Member();
		ret.name = name;
		ret.kind = FFun(f);
		ret.pos = if (pos == null) f.expr.pos else pos;
		ret.isPublic = isPublic;
		return ret;
	}
	static public function ofHaxe(f:Field) {
		var ret = new Member();
		
		ret.name = f.name;
		ret.doc = f.doc;
		ret.pos = f.pos;
		ret.kind = f.kind;
		
		//switch (f.kind) {
			//case FFun(f):
				//switch (f.expr.expr) {
					//case EMeta(s, e):
						//f = Reflect.copy(f);
						//ret.kind = FFun(f);
						//f.expr = e;
						//
					//default:
				//}
			//default:
		//}
		
		if (f.meta != null)
			for (m in f.meta) 
				ret.addMeta(m.name, m.pos, m.params);
		
		for (a in f.access) 
			switch (a) {
				case APublic: ret.isPublic = true;
				case APrivate: ret.isPublic = false;
				
				case AStatic: ret.isStatic = true;
				
				case AOverride: ret.isOverride = true;
				
				case ADynamic: ret.isBound = false;
				case AInline: ret.isBound = true;
				case AMacro: ret.excluded = true;
			}
			
		return ret;
	}
	
	static public function plain(name:String, type:ComplexType, pos:Position, ?e) {
		return ofHaxe( {
			name: name, 
			doc: null,
			access: [],
			kind: FVar(type, e),
			pos: pos,
			meta: []
		});
	}
}
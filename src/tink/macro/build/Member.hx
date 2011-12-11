package tink.macro.build;
 
import haxe.macro.Expr;
import tink.macro.tools.Printer;
import tink.util.Outcome;

using Lambda;
using tink.macro.tools.ExprTools;

class Member {
	public var name : String;
	public var doc : Null<String>;
	public var kind : FieldType;
	public var pos : Position;
	public var meta:Hash<Meta>;
	
	public var isOverride:Bool;
	public var isStatic:Bool;
	public var isBound:Null<Bool>;
	public var isPublic:Null<Bool>;
	
	public function new() {
		this.isOverride = this.isStatic = false;
		this.meta = new Hash();
	}
	public function withPos(pos:Position):Member {
		var ret = Reflect.copy(this);
		ret.pos = pos;
		return ret;
	}
	public function addMeta(name, pos, ?params) {
		meta.set(name, {
			name: name,
			pos: pos,
			params: if (params == null) [] else params
		});
	}
	public function disallowMeta(id:String, master:String) {
		if (meta.exists(id))
			meta.get(id).pos.error('cannot use tag ' + id + ' if ' + master + ' is used');
	}
	public function extractMeta(name) {
		return
			if (meta.exists(name)) {
				var ret = meta.get(name);
				meta.remove(name);
				return Success(ret);
			}
			else return Failure();
	}
	public function toString() {
		var ret = '';
		for (m in meta)
			ret += '@' + m.name + Printer.printExprList('', m.params);
		if (isStatic) ret += 'static ';
		if (isPublic == true) ret += 'public ';
		else if (isPublic == false) ret += 'private ';
		switch (kind) {
			case FVar(t, e): 
				ret += 'var ' + name + ':' + Printer.printType('', t);
				if (e != null)
					ret += ' = ' + e.toString();
				ret += ';';
			case FProp(get, set, t, e):
				ret += 'var ' + name + '(' + get + ', ' + set + '):' + Printer.printType('', t);
				if (e != null)
					ret += ' = ' + e.toString();
				ret += ';';
			case FFun(f):
				ret += Printer.printFunction(f, name);
		}
		return ret;
	}
	public function toHaxe() {
		return {
			name : name,
			doc : doc,
			access : haxeAccess(),
			kind : kind,
			pos : pos,
			meta : meta.array(),			
		}
	}
	public function getFunction() {
		return
			switch (kind) {
				case FFun(f): Success(f);
				default: pos.makeError('not a function');
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
	static public function prop(name:String, t:ComplexType, pos, ?readonly = false) {
		var ret = new Member();
		ret.name = name;
		ret.isPublic = true;
		ret.pos = pos;
		ret.kind = FProp('get_' + name, readonly ? 'null' : ('set_' + name), t);
		return ret;
	}
	static public function method(name:String, f:Function, ?pos, ?isPublic = true) {
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
		
		for (m in f.meta) 
			ret.meta.set(m.name, m);
		
		for (a in f.access) 
			switch (a) {
				case APublic: ret.isPublic = true;
				case APrivate: ret.isPublic = false;
				
				case AStatic: ret.isStatic = true;
				
				case AOverride: ret.isOverride = true;
				
				case ADynamic: ret.isBound = false;
				case AInline: ret.isBound = true;
			}
			
		return ret;
	}
}
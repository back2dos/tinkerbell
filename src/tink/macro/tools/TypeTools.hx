package tink.macro.tools;

/**
 * ...
 * @author back2dos
 */
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using tink.macro.tools.ExprTools;
using tink.core.types.Outcome;

class TypeTools {
	static var types = new IntHash<Type>();
	static var idCounter = 0;
	
	@:macro static public function getType(id:Int):Type {
		return types.get(id);
	}
	static public function getID(t:Type) {
		return
			switch (reduce(t)) {
				case TInst(t, _): t.toString();
				case TEnum(t, _): t.toString();
				default: null;
			}
	}
	static public function getFields(t:Type) {
		return
			switch (reduce(t)) {
				case TInst(t, _): t.get().fields.get().asSuccess();
				case TAnonymous(anon): anon.get().fields.asSuccess();
				default: 'type has no fields'.asFailure();
			}
	}
	static public function getStatics(t:Type) {
		return
			switch (reduce(t)) {
				case TInst(t, _): t.get().statics.get().asSuccess();
				default: 'type has no statics'.asFailure();
			}
	}
	static public function toString(t:ComplexType) {
		return Printer.printType('', t);
	}
	static public function isSubTypeOf(t:Type, of:Type, ?pos) {
		return 
			ECheckType(ECheckType('null'.resolve(), toComplex(t)).at(pos), toComplex(of)).at(pos).typeof();
	}
	static public function isDynamic(t:Type) {
		return switch(reduce(t)) {
			case TDynamic(_): true;
			default: false;
		}
	}
	static public function toType(t:ComplexType, ?pos) {	
		return [
			'_'.define(t, pos),
			'_'.resolve(pos)
		].toBlock(pos).typeof();
	}
	static public inline function instantiate(t:TypePath, ?args, ?pos) {
		return ENew(t, args == null ? [] : args).at(pos);
	}
	static public function asTypePath(s:String, ?params):TypePath {
		var parts = s.split('.');
		var name = parts.pop(),
			sub = null;
		if (parts.length > 0 && parts[parts.length - 1].charCodeAt(0) < 0x5B) {
			sub = name;
			name = parts.pop();
		}
		return {
			name: name,
			pack: parts,
			params: params == null ? [] : params,
			sub: sub
		}
	}
	static public inline function asComplexType(s:String, ?params) {
		return TPath(asTypePath(s, params));
	}
	static public inline function reduce(type:Type, ?once) {
		return Context.follow(type, once);
	}
	static public function isVar(field:ClassField) {
		return switch (field.kind) {
			case FVar(_, _): true;
			default: false;
		}
	}
	static public function register(type:Type):Int {
		var id = idCounter++;
		types.set(id, type);
		return id;
	}
	static function paramsToComplex(params:Array<Type>):Array<TypeParam> {
		var ret = [];
		for (p in params) 
			ret.push(TPType(toComplex(p, true)));
		return ret;
	}
	static function baseToComplex(t:BaseType, params:Array<Type>) {
		return asComplexType(t.module + '.' + t.name, paramsToComplex(params));
	}
	static public function toComplex(type:Type, ?pretty = false):ComplexType {
		return 
			if (pretty) {
				switch (type) {
					case TEnum(t, params):
						baseToComplex(t.get(), params);
					case TInst(t, params):	
						baseToComplex(t.get(), params);
					case TType(t, params):
						baseToComplex(t.get(), params);
					case TLazy(f):
						toComplex(f(), true);
					//TODO: check TDynamic here
					default: toComplex(type, false);
				}
			}
			else
				TPath({
					pack : ['haxe','macro'],
					name : 'MacroType',
					params : [TPExpr('tink.macro.tools.TypeTools.getType'.resolve().call([register(type).toExpr()]))],
					sub : null,				
				});		
	}	
}
package tink.macro.tools;

/**
 * ...
 * @author back2dos
 */
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using tink.macro.tools.ExprTools;
using tink.macro.tools.PosTools;
using tink.core.types.Outcome;

class TypeTools {
	static var types = new IntHash<Type>();
	static var idCounter = 0;
	@:macro static public function getType(id:Int):Type {
		return types.get(id);
	}
	static public function getID(t:Type, ?reduced = true) {
		if (reduced)
			t = reduce(t);
		return
			switch (t) {
				case TInst(t, _): t.toString();
				case TEnum(t, _): t.toString();
				case TType(t, _): t.toString();
				default: null;
			}
	}
	static public function accessToName(v:VarAccess) {
		return
			switch (v) {
				case AccNormal, AccInline: 'default';
				case AccNo: 'null';
				case AccNever: 'never';
				case AccResolve: throw 'not implemented';
				case AccRequire(r): 'not implemented';	
				case AccCall(m): m;
			}		
	}
	static function getDeclaredFields(t:ClassType, out:Array<ClassField>, marker:Hash<Bool>) {
		for (field in t.fields.get()) 
			if (!marker.exists(field.name)) {
				marker.set(field.name, true);
				out.push(field);
			}
		if (t.isInterface)
			for (t in t.interfaces)
				getDeclaredFields(t.t.get(), out, marker);
		else 
			if (t.superClass != null)
				getDeclaredFields(t.superClass.t.get(), out, marker);		
	}
	static function getBlankFields(t:ClassType, params:Array<Type>, out:Array<Field>, marker:Hash<Bool>) {
		var subst = new Hash<ComplexType>();
		for (i in 0...t.params.length) 
			subst.set(
				t.params[i].name,
				switch (params[i]) {
					case TInst(c, _):
						var c = c.get();
						if (c.kind == KTypeParameter) 
							asComplexType(c.name);
						else 
							toComplex(params[i]);
					default:
						toComplex(params[i]);
				}
			);
		
		for (field in t.fields.get()) 
			if (!marker.exists(field.name)) {
				var kind = 
					switch (field.kind) {
						case FVar(read, write): 
							FProp(
								accessToName(read), 
								accessToName(write), 
								field.pos.makeBlankType()
							);
						case FMethod(k): 
							switch (k) {
								case MethMacro: null;
								default: 
									switch (reduce(field.type)) {
										case TFun(args, _):
											var argList = [];
											for (arg in args)
												argList.push(FunctionTools.toArg(arg.name, field.pos.makeBlankType()));
											FFun({
												args : argList,
												ret: field.pos.makeBlankType(),
												expr: null,
												params: []
											});
										default: null;
									}
							}
					}
				if (kind != null) {
					marker.set(field.name, true);
					out.push( {
						name: field.name,
						pos: field.pos,
						kind: kind,
						meta: {
							var res = field.meta.get();//this hopefully creates a copy
							for (m in res)
								for (i in 0...m.params.length)
									m.params[i] = m.params[i].substParams(subst);
							res;
						},
						access: field.isPublic ? [APublic] : [APrivate]
					});					
				}
			}
		if (t.isInterface)
			for (t in t.interfaces)
				getBlankFields(t.t.get(), t.params, out, marker);
		else 
			if (t.superClass != null)
				getBlankFields(t.superClass.t.get(), t.superClass.params, out, marker);
	}
	static public function getFields(t:Type, ?substituteParams = true) {
		return
			switch (reduce(t)) {
				case TInst(c, params): 
					var c = c.get();
					if (substituteParams) {//TODO: take a shortcut when the type has no parameters
						var fields = [];
						getBlankFields(c, params, fields, new Hash());
						var anon = TAnonymous(fields);
						var actual = toComplex(t);
						return Context.currentPos().at(macro {
							var actual : $actual = null;
							var anon : $anon = actual;
							anon;
						}).typeof().map(function (t:Type)
							return
								switch (t) {
									case TAnonymous(anon): anon.get().fields;
									default: throw 'wtf just happened?';
								}
						);
					}
					else {
						var fields = [];
						getDeclaredFields(c, fields, new Hash());
						fields.asSuccess();
					}
				case TAnonymous(anon): anon.get().fields.asSuccess();
				default: Context.currentPos().makeFailure('type has no fields');
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
						var t = t.get();
						switch (t.kind) {
							case KTypeParameter: asComplexType(t.name);
							default: baseToComplex(t, params);
						}
					case TFun(args, ret):
						var cArgs = [];
						for (arg in args)
							cArgs.push(toComplex(arg.t, true));
						TFunction(cArgs, toComplex(ret, true));
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
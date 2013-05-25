package tink.macro.tools;

import haxe.macro.Printer;
import Type in Enums;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import tink.core.types.Outcome;

using tink.macro.tools.ExprTools;
using tink.macro.tools.PosTools;
using tink.macro.tools.FunctionTools;
using tink.core.types.Outcome;

class TypeTools {
	static var types = new Map<Int,Void->Type>();
	static var idCounter = 0;
	macro static public function getType(id:Int):Type {
		return types.get(id)();
	}
	static public function getID(t:Type, ?reduced = true) {
		if (reduced)
			t = reduce(t);
		return
			switch (t) {
				case TAbstract(t, _): t.toString();
				case TInst(t, _): t.toString();
				case TEnum(t, _): t.toString();
				case TType(t, _): t.toString();
				default: null;
			}
	}
	static public function accessToName(v:VarAccess, ?read = true) {
		return
			switch (v) {
				case AccNormal, AccInline: 'default';
				case AccNo: 'null';
				case AccNever: 'never';
				case AccCall: if (read) 'get' else 'set';
				default:
					throw 'not implemented';
			}		
	}
	static function getDeclaredFields(t:ClassType, out:Array<ClassField>, marker:Map<String,Bool>) {
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
	
	static var fieldsCache = new Map();
	static public function getFields(t:Type, ?substituteParams = true) 
		return
			switch (reduce(t)) {
				case TInst(c, _): 
					var id = c.toString(),
						c = c.get();
					if (!fieldsCache.exists(id)) {
						var fields = [];
						getDeclaredFields(c, fields, new Map());
						fieldsCache.set(id, fields.asSuccess());
					}
					var ret = fieldsCache.get(id);
					if (substituteParams && ret.isSuccess()) {
						var e = ECheckType(macro null, toComplex(t)).at();
						var fields = Reflect.copy(ret.sure());
						ret = fields.asSuccess();
						
						for (field in fields) 
							if (field.isPublic) {
								var member = e.field(field.name, e.pos);
								field.type = 
									switch (member.typeof()) {
										case Success(t): t;
										case Failure(f):
											switch (reduce(field.type)) {
												case TFun(args, _):
													var fArgs = [],
														fParams = [];
													for (a in args)
														fArgs.push(a.name.toArg());
													var f = (macro null).func(fArgs, false); 
													f.expr = EReturn(member.call(f.getArgIdents(), e.pos)).at(e.pos);
													f.asExpr(e.pos).typeof().sure();
												default:
													f.throwSelf();
													//trace(reduce(field.type) + ':' + field.name);
													//throw 'assert';
											}
									}	
							}
							else {
								var kind = 
									switch (field.kind) {
										case FVar(read, write): 
											FProp(accessToName(read), accessToName(write, true), field.pos.makeBlankType());
										default: 
											switch (reduce(field.type)) {
												case TFun(args, _):
													var argList = [];
													for (arg in args)
														argList.push(
															FunctionTools.toArg(arg.name, field.pos.makeBlankType())
														);
													FFun({
														args : argList,
														ret: field.pos.makeBlankType(),
														expr: null,
														params: []
													});
												default: null;
											}
									}
								if (kind != null) {
									var f = {
										name: field.name,
										pos: field.pos,
										kind: kind,
										access: [APrivate]
									};				
									field.type = ECheckType(e, TAnonymous([f])).at(e.pos).field(field.name, e.pos).typeof().sure();
								}								
							}
						}
					ret;
				case TAnonymous(anon): anon.get().fields.asSuccess();
				default: Context.currentPos().makeFailure('type has no fields');
			}
	
	static public function getStatics(t:Type) 
		return
			switch (reduce(t)) {
				case TInst(t, _): t.get().statics.get().asSuccess();
				default: 'type has no statics'.asFailure();
			}
	
	static public function toString(t:ComplexType) 
		return new Printer().printComplexType(t);
	
	static public function isSubTypeOf(t:Type, of:Type, ?pos) 
		return 
			ECheckType(ECheckType('null'.resolve(), toComplex(t)).at(pos), toComplex(of)).at(pos).typeof();
	
	static public function isDynamic(t:Type) 
		return switch(reduce(t)) {
			case TDynamic(_): true;
			default: false;
		}
	
	static public function toType(t:ComplexType, ?pos) 
		return [
			'_'.define(t, pos),
			'_'.resolve(pos)
		].toBlock(pos).typeof();
	
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
			if(sub == name) sub = null;
		}
		return {
			name: name,
			pack: parts,
			params: params == null ? [] : params,
			sub: sub
		};
	}
	static public inline function asComplexType(s:String, ?params) 
		return TPath(asTypePath(s, params));
	
	static public inline function reduce(type:Type, ?once) 
		return Context.follow(type, once);
	
	static public function isVar(field:ClassField) {
		return switch (field.kind) {
			case FVar(_, _): true;
			default: false;
		}
	}
	static public function register(type:Void->Type):Int {
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
	static function baseToComplex(t:BaseType, params:Array<Type>) 
		return asComplexType(t.module + '.' + t.name, paramsToComplex(params));
	
	static public function toComplex(type:Type, ?pretty = false):ComplexType {
		return 
			if (pretty) 
				switch (type) {
					case TEnum(t, params):
						var t = t.get();
						if(t.isPrivate)
							return toComplex(type, false);
						baseToComplex(t, params);
					case TInst(t, params):
						var t = t.get();
						if(t.isPrivate)
							return toComplex(type, false);
						switch (t.kind) {
							#if haxe3
							case KTypeParameter(constraints): asComplexType(t.name, paramsToComplex(constraints));
							#else
							case KTypeParameter: asComplexType(t.name);
							#end
							default: baseToComplex(t, params);
						}
					case TFun(args, ret):
						var cArgs = [];
						for (arg in args)
							cArgs.push(toComplex(arg.t, true));
						TFunction(cArgs, toComplex(ret, true));
					case TType(t, params):
						var t = t.get();
						if(t.isPrivate)
							return toComplex(type, false);
						baseToComplex(t, params);
					case TLazy(f):
						toComplex(f(), true);
					#if haxe3
					case TAbstract(t, params):
						var t = t.get();

						if(t.isPrivate)
							return toComplex(type, false); 

						baseToComplex(t, params);
					#end
					//TODO: check TDynamic here
					default: toComplex(type, false);
				}
			else 
				lazyComplex(function () return type);		
	}
	static public function lazyComplex(f:Void->Type) {
		return
			TPath({
				pack : ['haxe','macro'],
				name : 'MacroType',
				params : [TPExpr('tink.macro.tools.TypeTools.getType'.resolve().call([register(f).toExpr()]))],
				sub : null,				
			});
	}
}
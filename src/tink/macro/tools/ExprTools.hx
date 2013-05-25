package tink.macro.tools;

import Type in Inspect;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.PosInfos;
import tink.core.types.Outcome;
import haxe.macro.Printer;

using Lambda;
using StringTools;
using tink.macro.tools.PosTools;
using tink.macro.tools.ExprTools;
using tink.macro.tools.TypeTools;
using tink.core.types.Outcome;

typedef VarDecl = { name : String, type : ComplexType, expr : Null<Expr> };
typedef ParamSubst = {
	var exists(default, null):String->Bool;
	var get(default, null):String->ComplexType;
}

class ExprTools {

	static public inline function is(e:Expr, c:ComplexType) {
		return ECheckType(e, c).at(e.pos).typeof().isSuccess();
	}
	static var annotCounter = 0;
	static var annotations = new Map<Int,Dynamic>();
	static public function tag<D>(e:Expr, data:D) {
		annotations.set(annotCounter, data);
		return [(annotCounter++).toExpr(e.pos), e].toBlock(e.pos);
	}
	static public function finalize(e:Expr, ?nuPos:Position, ?rules:Dynamic<String>, ?skipFields = false, ?callPos:PosInfos) {
		if (nuPos == null)
			nuPos = Context.currentPos();
		if (rules == null)
			rules = { };
		function replace(s:String) 
			return {
				if (Reflect.hasField(rules, s)) 
					Reflect.field(rules, s)
				else if (s.startsWith('tmp')) {
					Reflect.setField(rules, s, MacroTools.tempName(String, '__tink' + s.substr(3)));
					replace(s);
				}
				else s;
			}
			
		return e.transform(function (e:Expr) {
			return
				if (Context.getPosInfos(e.pos).file != callPos.fileName) e;
				else {
					e.pos = nuPos;
					switch (e.expr) {
						case EVars(vars):
							for (v in vars) 
								v.name = replace(v.name);
							e;
						case EField(owner, field):
							if (skipFields) e;
							else owner.field(replace(field), e.pos);
						case EFunction(_, f):
							for (a in f.args)
								a.name = replace(a.name);
							e;
						case EObjectDecl(fields):
							if (!skipFields)
								for (f in fields)
									f.field = replace(f.field);
							e;
						default:	
							switch (e.getIdent()) {
								case Success(s): replace(s).resolve(e.pos);
								default: e;
							}
					}
				}
		});
	}
	static public function untag<D>(e:Expr):{data:D, e:Expr } {
		return
			switch (e.expr) {
				case EBlock(exprs): { e: exprs[1], data: annotations.get(exprs[0].getInt().sure()) };
				default: e.reject();
			}
	}
	static public function withPrivateAccess(e:Expr) {
		return 
			e.transform(function (e:Expr) 
				return
					switch (e.expr) {
						case EField(owner, field):
							getPrivate(owner, field, e.pos);
						default: e;
					}
			);
	}
	static public function getPrivate(e:Expr, field:String, ?pos) {
		return EMeta( { name: ':privateAccess', params: [], pos: pos }, e.field(field, pos)).at(pos);
	}
	static public function partial<D>(c:ComplexType, data:D, ?pos) 
		return ECheckType(macro null, c).at(pos).tag(data);
	
	static public function substitute(source:Expr, vars:Dynamic<Expr>, ?pos) 
		return 
			transform(source, function (e:Expr) {
				return
					switch (e.getIdent()) {
						case Success(name):
							if (Reflect.hasField(vars, name)) 
								Reflect.field(vars, name);
							else
								e;
						default: e;
					}
			}, pos);
	
	static public inline function ifNull(e:Expr, fallback:Expr) 
		return
			if (e.getIdent().equals('null')) fallback;
			else e;
	
	static public function substParams(source:Expr, subst:ParamSubst, ?pos):Expr 
		return crawl(
			source, 
			function (e) return e, 
			function (c:ComplexType) 
				return
					switch (c) {
						case TPath(p):
							if (p.pack.length == 0 && subst.exists(p.name)) 
								subst.get(p.name);
							else c;
						default: c;
					}
			, pos);
	
	static public function transform(source:Expr, transformer:Expr->Expr, ?pos):Expr 
		return crawl(source, transformer, function (t) return t, pos);
	
	static function crawlArray(a:Array<Dynamic>, transformer:Expr->Expr, retyper:ComplexType-> ComplexType, pos:Position):Array<Dynamic> {
		if (a == null) return a;
		var ret = [];
		for (v in a)
			ret.push(crawl(v, transformer, retyper, pos));
		return ret;
	}
	static public function getIterType(target:Expr) 
		return 
			(macro {
				var t = null,
					target = $target;
				for (i in target)
					t = i;
				t;
			}).finalize(target.pos).typeof();
	
	static public function yield(e:Expr, yielder:Expr->Expr):Expr {
		inline function rec(e) 
			return yield(e, yielder);
		return
			if (e == null) null;
			else if (e.expr == null) e;
			else switch (e.expr) {
				case EVars(_):
					(macro @:pos(e.pos) var x = { var x = 5; } ).typeof().sure();
					throw 'unreachable';//the above should cause an error
				case EParenthesis(e):
					EParenthesis(rec(e)).at(e.pos);
				case EBlock(exprs) if (exprs.length > 0): 
					exprs = exprs.copy();
					exprs.push(rec(exprs.pop()));
					EBlock(exprs).at(e.pos);
				case EIf(econd, eif, eelse)
					,ETernary(econd, eif, eelse):
					EIf(econd, rec(eif), rec(eelse)).at(e.pos);
				case ESwitch(e, cases, edef):
					cases = Reflect.copy(cases);//not exactly pretty, but does the job
					for (c in cases)
						c.expr = rec(c.expr);
					ESwitch(e, cases, rec(edef)).at(e.pos);
				case EFor(it, expr):
					EFor(it, rec(expr)).at(e.pos);
				case EWhile(cond, body, normal):
					EWhile(cond, rec(body), normal).at(e.pos);
				case ECheckType(e, t):
					ECheckType(rec(e), t).at(e.pos);
				case EMeta(s, e):
					EMeta(s, rec(e)).at(e.pos);
				case EUntyped(e):
					EUntyped(rec(e)).at(e.pos);
				case EBreak, EContinue: e;
				case EBinop(OpArrow, value, jump) if (jump.expr == EContinue || jump.expr == EBreak):
					macro @:pos(e.pos) {
						${rec(value)};
						$jump;
					}
				default: yielder(e);
			}
	}
			
	static function crawl(target:Dynamic, transformer:Expr->Expr, retyper:ComplexType->ComplexType, pos:Position):Dynamic {
		return
			if (Std.is(target, Array)) 
				crawlArray(target, transformer, retyper, pos);
			else
				switch (Inspect.typeof(target)) {
					case TNull, TInt, TFloat, TBool, TFunction, TUnknown, TClass(_): target;
					case TEnum(e): 
						var ret:Dynamic = Inspect.createEnumIndex(e, Inspect.enumIndex(target), crawlArray(Inspect.enumParameters(target), transformer, retyper, pos));
						return
							if (Inspect.getEnum(ret) == ComplexType) retyper(ret);
							else ret;
					case TObject:
						var ret:Dynamic = { };
						for (field in Reflect.fields(target))
							Reflect.setField(ret, field, crawl(Reflect.field(target, field), transformer, retyper, pos));
						if (Std.is(ret.expr, ExprDef)) {
							ret = transformer(ret);
							if (pos != null) ret.pos = pos;
						}
						ret;
				}
	}

	static public function map(source:Expr, f:Expr->Array<VarDecl>->Expr, ctx:Array<VarDecl>, ?pos:Position):Expr {
		if (ctx == null) 
			if (context == null) ctx = [];
			else ctx = context;
		
		function rec(e, ?inner)
			return map(e, f, inner == null ? ctx : inner, pos);
		if (source == null || source.expr == null) return source;
		var mappedSource = f(source, ctx);
		if (mappedSource != source) return mappedSource;
		
		var ret = switch(mappedSource.expr) {
			case ECheckType(e, t): ECheckType(rec(e), t);
			case ECast(e, t): ECast(rec(e), t);
			case EArray(e1, e2): EArray(rec(e1), rec(e2));
			case EField(e, field): EField(rec(e), field);
			case EParenthesis(e):  EParenthesis(rec(e));
			case ECall(e, params): ECall(rec(e), mapArray(params, f, ctx, pos));
			case EIf(econd, eif, eelse): EIf(rec(econd), rec(eif), rec(eelse));
			case ETernary(econd, eif, eelse): ETernary(rec(econd), rec(eif), rec(eelse));
			case EBlock(exprs): EBlock(exprs.mapArray(f, ctx.copy(), pos));
			case EArrayDecl(exprs): EArrayDecl(exprs.mapArray(f, ctx, pos));
			case EIn(e1, e2): EIn(rec(e1), rec(e2));
			case EWhile(econd, e, normalWhile): EWhile(rec(econd), rec(e), normalWhile);
			case EUntyped(e): EUntyped(rec(e));
			case EThrow(e): EThrow(rec(e));
			case EReturn(e): EReturn(rec(e));
			case EDisplay(e, t): EDisplay(rec(e), t);
			case EDisplayNew(t): EDisplayNew(t);
			case EUnop(op, postFix, e): EUnop(op, postFix, rec(e));
			case ENew(t, params): ENew(t, params.mapArray(f, ctx, pos));
			case EBinop(op, e1, e2): EBinop(op, rec(e1), rec(e2));
			case EObjectDecl(fields):
				var newFields = [];
				for (field in fields)
					newFields.push( { field:field.field, expr:rec(field.expr) } );
				EObjectDecl(newFields);
			case ESwitch(expr, cases, def):
				var newCases = cases;
				newCases = [];
				expr = rec(expr); 
				switch (expr.typeof(ctx).sure().reduce()) {
					case TEnum(e, _):
						var enumDef = e.get();
						for (c in cases) {
							var caseValues = [],
								innerCtx = ctx.copy();
							for (v in c.values) {
								var newVal = v;
								switch (v.expr) {
									case ECall(e, params):
										switch (e.getIdent()) {
											case Success(s):
												if (!enumDef.constructs.exists(s))
													e.reject('Constructor is not a part of ' + enumDef.name);
												newVal = enumDef.module.split('.').concat([enumDef.name, s]).drill(e.pos); 
												if (caseValues.length == 0) {
													switch (newVal.typeof(ctx).sure().reduce()) {
														case TFun(args, _):
															for (arg in 0...args.length) {
																innerCtx.push({ 
																	name:params[arg].getName().sure(), 
																	type: args[arg].t.toComplex(), 
																	expr: null 
																});
															}
														default:
															e.reject('Constructor may not have arguments');
													}
												}
												newVal = newVal.call(params, v.pos);
											default:
												e.reject();
										}
									default:
										v.reject();
								}
								caseValues.push(rec(newVal));
							}
							newCases.push( { expr: rec(c.expr, innerCtx), values: caseValues } );
						}
					case _:
						for (c in cases) {
							var caseValues = [];
							for (v in c.values) 
								caseValues.push(rec(v));
							newCases.push( { expr: rec(c.expr), values: caseValues } );
						}
				}
				ESwitch(expr, newCases, rec(def));
			case EFor(it, expr):
				switch(it.expr) {
					case EIn(itIdent, itExpr):
						var innerCtx = ctx.copy();
						switch(itExpr.typeof(ctx)) {
							case Success(t):
								if (t.getID() == "IntIter")
									innerCtx.push( { name:itIdent.getIdent().sure(), type: "Int".asComplexType(), expr:null } );
								else
									innerCtx.push( { name:itIdent.getIdent().sure(), type: null, expr:itExpr.field("iterator").call().field("next").call() } );
								EFor(it, rec(expr, innerCtx));
							default:
								innerCtx.push( { name:itIdent.getIdent().sure(), type: null, expr:itExpr.field("iterator").call().field("next").call() } );
								EFor(it, rec(expr, innerCtx));
						}
					default: 
						Context.error("Internal error in " + mappedSource.toString(), mappedSource.pos);
				}
			case ETry(e, catches):
				var newCatches = [];
				for (c in catches)
				{
					var innerCtx = ctx.copy();
					innerCtx.push({ name:c.name, expr: null, type:c.type });
					newCatches.push({name:c.name, expr:rec(c.expr, innerCtx), type:c.type});
				}
				ETry(rec(e), newCatches);
			case EFunction(name, func):
				var innerCtx = ctx.copy();
				for (arg in func.args)
					innerCtx.push( { name:arg.name, type:arg.type, expr:null } );
				func.expr = rec(func.expr, innerCtx);
				EFunction(name, func);
			case EVars(vars):
				var ret = [];
				for (v in vars)
				{
					var vExpr = v.expr == null ? null : map(v.expr, f, ctx);
					if (v.type == null && vExpr != null)
						v.type = vExpr.typeof(ctx).sure().toComplex();
					ctx.push({ name:v.name, expr:null, type:v.type });
					ret.push({ name:v.name, expr:vExpr == null ? null : vExpr, type:v.type });
				}
				EVars(ret);
			default:
				mappedSource.expr;
		}
		return ret.at(pos == null ? source.pos : pos);
	}
	
	static public function mapArray(source:Array<Expr>, f:Expr->Array<VarDecl>->Expr, ctx:Array<VarDecl>, ?pos) {
		var ret = [];
		for (e in source)
			ret.push(map(e, f, ctx, pos));
		return ret;
	}
	
	static public inline function iterate(target:Expr, body:Expr, ?loopVar:String = 'i', ?pos:Position) 
		return EFor(EIn(loopVar.resolve(pos), target).at(pos), body).at(pos);
	
	static public function toFields(object:Dynamic<Expr>, ?pos:Position) {
		var args = [];
		for (field in Reflect.fields(object))
			args.push( { field:field, expr: untyped Reflect.field(object, field) } );
		return EObjectDecl(args).at(pos);
	}

	static public inline function log(e:Expr, ?pos:PosInfos):Expr {
		haxe.Log.trace(e.toString(), pos);
		return e;
	}
	
	static public inline function reject(e:Expr, ?reason:String = 'cannot handle expression'):Dynamic 
		return e.pos.error(reason);
	
	static public inline function toString(e:Expr):String 
		return tink.macro.tools.Printer.printExpr('', e);
		//return new haxe.macro.Printer().printExpr(e);
		
	static public inline function at(e:ExprDef, ?pos:Position) 
		return {
			expr: e,
			pos: pos.getPos()
		};
	
	static public inline function instantiate(s:String, ?args:Array<Expr>, ?params:Array<TypeParam>, ?pos:Position) 
		return s.asTypePath(params).instantiate(args, pos);
	
	static public inline function assign(target:Expr, value:Expr, ?op:Binop, ?pos:Position) 
		return binOp(target, value, op == null ? OpAssign : OpAssignOp(op), pos);
	
	static public inline function define(name:String, ?init:Expr, ?typ:ComplexType, ?pos:Position) 
		return at(EVars([ { name:name, type: typ, expr: init } ]), pos);
	
	static public inline function add(e1, e2, ?pos) 
		return binOp(e1, e2, OpAdd, pos);
		
	static public inline function unOp(e, op, ?postFix = false, ?pos) 
		return EUnop(op, postFix, e).at(pos);
	
	static public inline function binOp(e1, e2, op, ?pos) 
		return EBinop(op, e1, e2).at(pos);
		
	static public inline function field(e, field, ?pos) 
		return EField(e, field).at(pos);
		
	static public inline function call(e, ?params, ?pos) 
		return ECall(e, params == null ? [] : params).at(pos);
		
	static public inline function toExpr(v:Dynamic, ?pos:Position) 
		return Context.makeExpr(v, pos.getPos());
		
	static public inline function toArray(exprs:Iterable<Expr>, ?pos) 
		return EArrayDecl(exprs.array()).at(pos);
		
	static public inline function toMBlock(exprs, ?pos) 
		return EBlock(exprs).at(pos);
		
	static public inline function toBlock(exprs:Iterable<Expr>, ?pos) 
		return toMBlock(Lambda.array(exprs), pos);
		
	static inline function isUC(s:String) 
		return StringTools.fastCodeAt(s, 0) < 0x5B;
		
	static public function drill(parts:Array<String>, ?pos:Position, ?target:Expr) {
		if (target == null) 
			target = at(EConst(CIdent(parts.shift())), pos);
		for (part in parts)
			target = field(target, part, pos);
		return target;		
	}
	
	static public inline function resolve(s:String, ?pos) 
		return drill(s.split('.'), pos);
		
	static var contexts = new List();
	static var context = null;
	static public function inContext<A>(f:Void->A, locals) {//TODO: I think this is obsolete
		contexts.push(context);
		context = locals;
		var ret = f();
		context = contexts.pop();
		return ret;
	}
	static public function lazyType(expr:Expr, ?locals) {
		return (function () {
			return typeof(expr, locals).sure();
		}).lazyComplex();
	}
	static public function typeof(expr:Expr, ?locals) {
		return
			try {
				if (locals == null && context != null) 
					locals = context;
				if (locals != null) 
					expr = [EVars(locals).at(expr.pos), expr].toMBlock(expr.pos);
				Success(Context.typeof(expr));
			}
			catch (e:Error) {
				var m:Dynamic = e.message;
				e.pos.makeFailure(m);
			}
			catch (e:Dynamic) {
				expr.pos.makeFailure(e);
			}				
	}	
	static public inline function cond(cond:Expr, cons:Expr, ?alt:Expr, ?pos) 
		return EIf(cond, cons, alt).at(pos);
		
	static public function isWildcard(e:Expr) 
		return 
			switch(e.expr) {
				case EConst(c):
					switch (c) {
						case CIdent(s): s == '_';
						default: false;
					}
				default: false;
			}
			
	static public function getString(e:Expr) 
		return 
			switch (e.expr) {
				case EConst(c):
					switch (c) {
						case CString(string): Success(string);
						default: e.pos.makeFailure(NOT_A_STRING);
					}
				default: e.pos.makeFailure(NOT_A_STRING);
			}			
		
	static public function getInt(e:Expr) 
		return 
			switch (e.expr) {
				case EConst(c):
					switch (c) {
						case CInt(id): Success(Std.parseInt(id));
						default: e.pos.makeFailure(NOT_AN_INT);
					}
				default: e.pos.makeFailure(NOT_AN_INT);
			}							
	
	static public function getIdent(e:Expr) 
		return 
			switch (e.expr) {
				case EConst(c):
					switch (c) {
						case CIdent(id): Success(id);
						default: e.pos.makeFailure(NOT_AN_IDENT);
					}
				default: 
					e.pos.makeFailure(NOT_AN_IDENT);
			}					
	
	static public function getName(e:Expr) 
		return 
			switch (e.expr) {
				case EConst(c):
					switch (c) {
						case CString(s), CIdent(s): Success(s);
						default: e.pos.makeFailure(NOT_A_NAME);
					}
				default: e.pos.makeFailure(NOT_A_NAME);
			}					
	
	static public function getFunction(e:Expr) 
		return
			switch (e.expr) {
				case EFunction(_, f): Success(f);
				default: e.pos.makeFailure(NOT_A_FUNCTION);
			}
	
	static inline var NOT_AN_INT = "integer constant expected";
	static inline var NOT_AN_IDENT = "identifier expected";
	static inline var NOT_A_STRING = "string constant expected";
	static inline var NOT_A_NAME = "name expected";
	static inline var NOT_A_FUNCTION = "function expected";
	static inline var EMPTY_EXPRESSION = "expression expected";	
	
	static public function match(expr:Expr, pattern:Expr) 
		return new Matcher().match(expr, pattern);
	
}

private class Matcher {
	var exprs:Dynamic<Expr>;
	var strings:Dynamic<String>;
	public function new() {
		this.exprs = {};
		this.strings = {};
	}
	public function match(expr:Expr, pattern:Expr) {
		return
			try 
			{
				recurse(expr, pattern);
				{ 
					exprs: exprs, 
					strings: strings,//TODO: deprecate
					names: strings,
					pos: expr.pos
				}.asSuccess();
			}
			catch (e:String) {
				e.asFailure();
			}
	}
	function matchObject(x1:Dynamic, x2:Dynamic) {
		if (x2 == null) throw Std.string(x2) + ' expected but found ' + Std.string(x1);
		for (f in Reflect.fields(x1)) 
			matchAny(Reflect.field(x1, f), Reflect.field(x2, f));
	}
	function matchString(s1:String, s2:String) {
		if (s2 == null) 
			equal(s1, s2);
		else if (s2.startsWith('eval__') || s2.startsWith('NAME__')) 
			Reflect.setField(strings, s2.substr(6), s1);
		else
			equal(s1, s2);
	}
	function equal(x1:Dynamic, x2:Dynamic) {
		if (x1 != x2) throw Std.string(x2) + ' expected but found ' + Std.string(x1);
	}
	function matchAny(x1:Dynamic, x2:Dynamic) {
		switch (Inspect.typeof(x1)) {
			case TNull, TInt, TFloat, TBool: equal(x1, x2);
			case TObject: 
				if (Std.is(x1.expr, ExprDef)) recurse(x1, x2);
				else matchObject(x1, x2);
			case TFunction: 
				throw 'unexpected';
			case TClass(c):
				if (c == Array) matchArray(x1, x2);
				else if (c == String) matchString(x1, x2);
				else throw 'unexpected';
			case TEnum(_): matchEnum(x1, x2);
			case TUnknown:
		}
	}
	function matchArray(a1:Array<Dynamic>, a2:Array<Dynamic>) {
		equal(a1.length, a2.length);
		for (i in 0...a1.length)
			matchAny(a1[i], a2[i]);
	}
	function matchEnum(e1:Dynamic, e2:Dynamic) {
		equal(Inspect.enumConstructor(e1), Inspect.enumConstructor(e2));
		matchArray(Inspect.enumParameters(e1), Inspect.enumParameters(e2));
	}
	function recurse(expr:Expr, pattern:Expr) {
		if (pattern == null) throw 'nothing expected but found ' + expr.toString();
		switch (pattern.getIdent()) {
			case Success(s):
				if (s.startsWith('$')) 
					Reflect.setField(exprs, s.substr(1), expr); 
				else if (s.startsWith('EXPR__')) 
					Reflect.setField(exprs, s.substr(6), expr); 
				else
					matchEnum(expr.expr, pattern.expr);
			default: 
				matchEnum(expr.expr, pattern.expr);
		}
	}
}
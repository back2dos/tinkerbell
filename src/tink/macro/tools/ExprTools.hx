package tink.macro.tools;

private typedef Inspect = Type;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.PosInfos;
import tink.core.types.Outcome;

using Lambda;
using tink.macro.tools.PosTools;
using tink.macro.tools.ExprTools;
using tink.macro.tools.TypeTools;
using tink.core.types.Outcome;

typedef VarDecl = { name : String, type : ComplexType, expr : Null<Expr> };

class ExprTools {

	static public inline function is(e:Expr, c:ComplexType) {
		return ECheckType(e, c).at(e.pos).typeof().isSuccess();
	}
	static var annotCounter = 0;
	static var annotations = new IntHash<Dynamic>();
	static public function tag<D>(e:Expr, data:D) {
		annotations.set(annotCounter, data);
		return [(annotCounter++).toExpr(e.pos), e].toBlock(e.pos);
	}
	static public function untag<D>(e:Expr):{data:D, e:Expr } {
		return
			switch (e.expr) {
				case EBlock(exprs): { e: exprs[1], data: annotations.get(exprs[0].getInt().sure()) };
				default: e.reject();
			}
	}

	static public function getPrivate(e:Expr, field:String, ?pos) {
		if (pos == null) pos = e.pos;
		
		var type = ComplexType.TAnonymous([ { 
			name: field,
			access: [APrivate],
			kind: FProp('default', 'null', pos.makeBlankType()),
			pos: pos
		}]);
		return ECheckType(e, type).at(pos).field(field, pos);
	}
	static public function partial<D>(c:ComplexType, data:D, ?pos) {
		return ECheckType('null'.resolve(), c).at(pos).tag(data);
	}
	static public function substitute(source:Expr, vars:Dynamic<Expr>, ?pos) {
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
	}
	static public inline function ifNull(e:Expr, fallback:Expr) {
		return
			if (e.getIdent().equals('null')) fallback;
			else e;
	}

	static public function transform(source:Expr, transformer:Expr->Expr, ?pos):Expr {
		return crawl(source, transformer, pos);
	}
	static function crawlArray(a:Array<Dynamic>, transformer:Expr->Expr, pos:Position):Dynamic {
		var ret = [];
		for (v in a)
			ret.push(crawl(v, transformer, pos));
		return ret;
	}
	static public function getIterType(target:Expr) {
		var e = macro {
			var t = null,
				target = $target;
			for (i in target)
				t = i;
			t;
		};
		return e.typeof();
	}
	static function crawl(target:Dynamic, transformer:Expr->Expr, pos:Position) {
		return
			if (Std.is(target, Array)) 
				crawlArray(target, transformer, pos);
			else
				switch (Inspect.typeof(target)) {
					case TNull, TInt, TFloat, TBool, TFunction, TUnknown, TClass(_): target;
					case TEnum(e): 
						Inspect.createEnumIndex(e, Inspect.enumIndex(target), crawlArray(Inspect.enumParameters(target), transformer, pos));
					case TObject:
						var ret:Dynamic = { };
						for (field in Reflect.fields(target))
							Reflect.setField(ret, field, crawl(Reflect.field(target, field), transformer, pos));
						if (Std.is(ret.expr, ExprDef)) {
							ret = transformer(ret);
							if (pos != null) ret.pos = pos;
						}
						ret;
				}
	}

	static public function map(source:Expr, f:Expr->Array<VarDecl>->Expr, ctx:Array<VarDecl>, ?pos:Position):Expr {
		function rec(e, ?ctx)
			return map(e, f, ctx, pos);
		if (source == null)	return null;
		var mappedSource = f(source, ctx);
		if (mappedSource != source) return mappedSource;
		
		return (switch(mappedSource.expr)
		{
			case ECheckType(e, t): ECheckType(rec(e), t);
			case ECast(e, t): ECast(rec(e), t);
			case EArray(e1, e2): EArray(rec(e1), rec(e2));
			case EField(e, field): EField(rec(e), field);
			case EParenthesis(e):  EParenthesis(rec(e));
			case ECall(e, params): ECall(rec(e), params.mapArray(f, ctx, pos));
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
			case EUnop(op, postFix, e): EUnop(op, postFix, rec(e));
			case ENew(t, params): ENew(t, params.mapArray(f, ctx, pos));
			case EBinop(op, e1, e2): EBinop(op, rec(e1), rec(e2));
			case EObjectDecl(fields):
				var newFields = [];
				for (field in fields)
					newFields.push( { field:field.field, expr:rec(field.expr) } );
				EObjectDecl(newFields);
			case ESwitch(expr, cases, def):
				var newCases = [];
				for (c in cases)
				{
					var newValues:Array<Expr> = [];
					for (v in c.values)
						newValues.push(rec(v));
					
					switch(newValues[0].expr)
					{
						case ECall(i, params):
							var t = Context.typeof(i);
							switch(t)
							{
								case TFun(args, ret):
									var innerCtx = ctx.copy();
									for (arg in 0...args.length)
									{
										innerCtx.push( { name:params[arg].getName().sure(), type: args[arg].t.toComplex(), expr: null } );
									}
									newCases.push({expr:rec(c.expr, innerCtx), values:newValues});
								default: return Context.error("Expected function but found " +t, i.pos);
							}
						default: newCases.push( { expr:rec(c.expr), values:c.values } );
					}
				}
				ESwitch(rec(expr), newCases, rec(def));
			case EFor(it, expr):
			{
				switch(it.expr)
				{
					case EIn(itIdent, itExpr):
						var innerCtx = ctx.copy();
						switch(itExpr.typeof(ctx))
						{
							case Success(t):
								if (t.getID() == "IntIter")
									innerCtx.push( { name:itIdent.getIdent().sure(), type: "Int".asComplexType(), expr:null } );
								else
									innerCtx.push( { name:itIdent.getIdent().sure(), type: null, expr:itExpr.field("iterator").call().field("next").call() } );
								EFor(it, rec(expr, innerCtx));
							default:
						}
					default: return Context.error("Internal error", mappedSource.pos);
				}
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
		}).at(mappedSource.pos);
	}
	static public function mapArray(source:Array<Expr>, f:Expr->Array<VarDecl>->Expr, ctx:Array<VarDecl>, ?pos)
	{
		var ret = [];
		for (e in source)
			ret.push(map(e, f, ctx, pos));
		return ret;
	}
	static public inline function iterate(target:Expr, body:Expr, ?loopVar:String = 'i', ?pos:Position) {
		return EFor(EIn(loopVar.resolve(pos), target).at(pos), body).at(pos);
	}
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
	static public inline function reject(e:Expr, ?reason:String = 'cannot handle expression'):Dynamic {
		return e.pos.error(reason);
	}
	///transforms an expression to readable code
	static public inline function toString(e:Expr):String {
		return Printer.print(e);
	}	
	static public inline function at(e:ExprDef, ?pos:Position) {
		return {
			expr: e,
			pos: pos.getPos()
		}
	}
	static public inline function instantiate(s:String, ?args:Array<Expr>, ?params:Array<TypeParam>, ?pos:Position) {
		return s.asTypePath(params).instantiate(args, pos);
	}
	static public inline function assign(target:Expr, value:Expr, ?pos:Position) {
		return binOp(target, value, OpAssign, pos);
	}
	///single variable declaration
	static public inline function define(name:String, ?init:Expr, ?typ:ComplexType, ?pos:Position) {
		return at(EVars([ { name:name, type: typ, expr: init } ]), pos);
	}
	static public inline function add(e1, e2, ?pos) {
		return binOp(e1, e2, OpAdd, pos);
	}
	static public inline function unOp(e, op, ?postFix = false, ?pos) {
		return EUnop(op, postFix, e).at(pos);
	}
	static public inline function binOp(e1, e2, op, ?pos) {
		return EBinop(op, e1, e2).at(pos);
	}
	static public inline function field(e, field, ?pos) {
		return EField(e, field).at(pos);
	}
	static public inline function call(e, ?params, ?pos) {
		return ECall(e, params == null ? [] : params).at(pos);
	}
	static public inline function toExpr(v:Dynamic, ?pos:Position) {
		return Context.makeExpr(v, pos.getPos());
	}
	static public inline function toArray(exprs:Iterable<Expr>, ?pos) {
		return EArrayDecl(exprs.array()).at(pos);
	}
	static public inline function toMBlock(exprs, ?pos) {
		return EBlock(exprs).at(pos);
	}
	static public inline function toBlock(exprs:Iterable<Expr>, ?pos) {
		return toMBlock(Lambda.array(exprs), pos);
	}
	static inline function isUC(s:String) {
		return StringTools.fastCodeAt(s, 0) < 0x5B;
	}
	///builds an expression from an identifier path
	static public function drill(parts:Array<String>, ?pos) {
		var first = parts.shift();
		var ret = at(EConst(isUC(first) ? CType(first) : CIdent(first)), pos);
		for (part in parts)
			ret = 
				if (isUC(part)) 
					at(EType(ret, part), pos);
				else 
					field(ret, part, pos);
		return ret;		
	}
	///resolves a `.`-separated path of identifiers
	static public inline function resolve(s:String, ?pos) {
		return drill(s.split('.'), pos);
	}
	///attempts to extract the type of an expression
	static public function typeof(expr:Expr, ?locals) {
		return
			try {
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
	static public inline function cond(cond:ExprRequire<Bool>, cons:Expr, ?alt:Expr, ?pos) {
		return EIf(cond, cons, alt).at(pos);
	}
	static public function isWildcard(e:Expr) {
		return 
			switch(e.expr) {
				case EConst(c):
					switch (c) {
						case CIdent(s): s == '_';
						default: false;
					}
				default: false;
			}
	}	
	///Attempts to extract a string constant from an expression.
	static public function getString(e:Expr) {
		return 
			switch (e.expr) {
				case EConst(c):
					switch (c) {
						case CString(string): Success(string);
						default: e.pos.makeFailure(NOT_A_STRING);
					}
				default: e.pos.makeFailure(NOT_A_STRING);
			}			
	}	
	///Attempts to extract an integer constant from an expression.
	static public function getInt(e:Expr) {
		return 
			switch (e.expr) {
				case EConst(c):
					switch (c) {
						case CInt(id): Success(Std.parseInt(id));
						default: e.pos.makeFailure(NOT_AN_INT);
					}
				default: e.pos.makeFailure(NOT_AN_INT);
			}							
	}
	///Attempts to extract an identifier (CIdent or CType) from an expression.
	static public function getIdent(e:Expr) {
		return 
			switch (e.expr) {
				case EConst(c):
					switch (c) {
						case CIdent(id), CType(id): Success(id);
						default: e.pos.makeFailure(NOT_AN_IDENT);
					}
				default: 
					e.pos.makeFailure(NOT_AN_IDENT);
			}					
	}
	///Attempts to extract a name (identifier or string) from an expression.
	static public function getName(e:Expr) {
		return 
			switch (e.expr) {
				case EConst(c):
					switch (c) {
						case CString(s), CIdent(s), CType(s): Success(s);
						default: e.pos.makeFailure(NOT_A_NAME);
					}
				default: e.pos.makeFailure(NOT_A_NAME);
			}					
	}
	///Attempts to extract a function from an expression.
	static public function getFunction(e:Expr) {
		return
			switch (e.expr) {
				case EFunction(_, f): Success(f);
				default: e.pos.makeFailure(NOT_A_FUNCTION);
			}
	}
	static inline var NOT_AN_INT = "integer constant expected";
	static inline var NOT_AN_IDENT = "identifier expected";
	static inline var NOT_A_STRING = "string constant expected";
	static inline var NOT_A_NAME = "name expected";
	static inline var NOT_A_FUNCTION = "function expected";
	static inline var EMPTY_EXPRESSION = "expression expected";	
}
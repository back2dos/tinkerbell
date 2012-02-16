package tink.macro.tools;

private typedef Inspect = Type;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.PosInfos;
import tink.core.types.Outcome;

using Lambda;
using tink.macro.tools.ExprTools;
using tink.core.types.Outcome;

class ExprTools {
	static public inline function getPos(pos:Position) {
		return 
			if (pos == null) 
				Context.currentPos();
			else
				pos;
	}
	static public inline function is(e:Expr, c:ComplexType) {
		return ECheckType(e, c).at(e.pos).typeof().isSuccess();
	}
	static public function annotations(e:Expr):Dynamic {
		var ret = untyped e.body;
		if (ret == null) untyped e.body = ret = { };
		return ret;
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
	static public function isIterable(target:Expr) {
		var e:Expr = AST.build( {
			var tmp = null;
			for (_ in $target)
				tmp = _;
			tmp;
		});
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
	static public inline function error(pos:Position, error:Dynamic):Dynamic {
		return Context.error(Std.string(error), pos);
	}
	static public inline function reject(e:Expr, ?reason:String = 'cannot handle expression'):Dynamic {
		return error(e.pos, reason);
	}
	///transforms an expression to readable code
	static public inline function toString(e:Expr):String {
		return Printer.print(e);
	}	
	static public inline function at(e:ExprDef, ?pos:Position) {
		return {
			expr: e,
			pos: getPos(pos)
		}
	}
	static public inline function assign(target:Expr, value:Expr, ?pos:Position) {
		return binOp(target, value, OpAssign, pos);
	}
	static public inline function toArg(name:String, ?t, ?opt = false, ?value = null):FunctionArg {
		return {
			name: name,
			opt: opt,
			type: t,
			value: value
		};
	}
	static public inline function func(e:Expr, ?args, ?ret, ?params, ?makeReturn = true):Function {
		return {
			args: args == null ? [] : args,
			ret: ret,
			params: params == null ? [] : params,
			expr: [if (makeReturn) at(EReturn(e), e.pos) else e].toBlock(e.pos)
		}		
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
		return Context.makeExpr(v, getPos(pos));
	}
	static public inline function toArray(exprs, ?pos) {
		return EArrayDecl(exprs).at(pos);
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
	static public function typeof(expr:Expr, ?locals):Outcome<Type, MacroError<Dynamic>> {
		return
			try {
				if (locals != null) 
					expr = [EVars(locals).at(expr.pos), expr].toMBlock(expr.pos);
				Success(Context.typeof(expr));
			}
			catch (e:Error) {
				e.pos.makeFailure(e.message);
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
	///used to easily construct failed outcomes
	static public function makeFailure<A, Reason>(pos:Position, reason:Reason):Outcome<A, MacroError<Reason>> {
		return Failure(new MacroError(reason, pos));
	}	
	///Attempts to extract a string from an expression.
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
	///Attempts to extract an identifier from an expression.
	static public function getIdent(e:Expr) {
		return 
			switch (e.expr) {
				case EConst(c):
					switch (c) {
						case CIdent(id), CType(id): Success(id);
						default: e.pos.makeFailure(NOT_AN_IDENT);
					}
				default: e.pos.makeFailure(NOT_A_STRING);
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
				default: e.pos.makeFailure(NOT_A_STRING);
			}					
	}
	static inline var NOT_AN_IDENT = "identifier expected";
	static inline var NOT_A_STRING = "string constant expected";
	static inline var NOT_A_NAME = "name expected";
	static inline var EMPTY_EXPRESSION = "expression expected";
	
}
private class MacroError<Data> implements ThrowableFailure {
	public var data(default, null):Data;
	public var pos(default, null):Position;
	public function new(data:Data, ?pos:Position) {
		this.data = data;
		this.pos =
			if (pos == null) 
				Context.currentPos();
			else 
				pos;
	}
	public function toString() {
		return 'Error@' + Std.string(pos) + ': ' + Std.string(data);
	}
	public function throwSelf():Dynamic {
		return Context.error(Std.string(data), pos);
	}
}
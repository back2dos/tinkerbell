package tink.macro.tools;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import tink.util.Outcome;

using tink.macro.tools.ExprTools;
class ExprTools {
	static public inline function getPos(pos:Position) {
		return 
			if (pos == null) 
				Context.currentPos();
			else
				pos;
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
	static public inline function log(e:Expr):Expr {
		trace(e.toString());
		return e;
	}
	static public inline function error(pos:Position, error:Dynamic):Dynamic {
		return Context.error(Std.string(error), pos);
	}
	static public inline function reject(e:Expr, ?reason:String = 'cannot handle expression') {
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
	static public inline function func(e:Expr, ?args, ?ret, ?params, ?makeReturn = true):Function {
		return {
			args: args == null ? [] : args,
			ret: ret,
			params: params == null ? [] : params,
			expr: if (makeReturn) at(EReturn(e), e.pos) else e
		}		
	}
	///single variable declaration
	static public inline function define(name:String, ?init:Expr, ?typ:ComplexType, ?pos:Position) {
		return at(EVars([ { name:name, type: typ, expr: init } ]), pos);
	}
	static public inline function add(e1, e2, ?pos) {
		return binOp(e1, e2, OpAdd, pos);
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
	static inline function toMBlock(exprs, ?pos) {
		return EBlock(exprs).at(pos);
	}
	static public inline function toBlock(exprs, ?pos) {
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
	static public function typeof(expr:Expr) {
		return
			try {
				Success(Context.typeof(expr));
			}
			catch (e:Dynamic) {
				failure(e, expr.pos);
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
	///shorthand for creating a failure outcome
	static function failure<A, Reason>(reason:Reason, ?pos:Position):Outcome<A, MacroError<Reason>> {
		return Failure(new MacroError(reason, pos));
	}	
	///Attempts to extract a string from an expression.
	static public function getString(e:Expr) {
		return 
			switch (e.expr) {
				case EConst(c):
					switch (c) {
						case CString(string): Success(string);
						default: failure(NOT_A_STRING, e.pos);
					}
				default: failure(NOT_A_STRING, e.pos);
			}			
	}	
	///Attempts to extract an identifier from an expression.
	static public function getIdent(e:Expr) {
		return 
			switch (e.expr) {
				case EConst(c):
					switch (c) {
						case CIdent(id), CType(id): Success(id);
						default: failure(NOT_AN_IDENT, e.pos);
					}
				default: failure(NOT_A_STRING, e.pos);
			}					
	}
	///Attempts to extract a name (identifier or string) from an expression.
	static public function getName(e:Expr) {
		return 
			switch (e.expr) {
				case EConst(c):
					switch (c) {
						case CString(s), CIdent(s), CType(s): Success(s);
						default: failure(NOT_A_NAME, e.pos);
					}
				default: failure(NOT_A_STRING, e.pos);
			}					
	}
	static inline var NOT_AN_IDENT = "identifier expected";
	static inline var NOT_A_STRING = "string expected";
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
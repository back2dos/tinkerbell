package tink.macro.tools;

import haxe.macro.Context;
import haxe.macro.Expr;
import tink.core.types.Outcome;

using tink.macro.tools.PosTools;
using tink.core.types.Outcome;

abstract PosContext(Int) to Int {
	static var stack = [];
	static var idCounter = 0;
	function new() this = idCounter++;
	
	static public function enter(pos:Position) {
		var ctx = new PosContext();
		stack.push({
			pos: pos,
			ctx: ctx
		});
		return ctx;
	}
	public function leave() {
		stack = [for (item in stack) if (item.ctx != this) item];
	}
	static public function get() {
		return
			if (stack.length == 0)
				Context.currentPos()
			else 
				stack[stack.length - 1].pos;
	}
}

class PosTools {
	
	static public function getOutcome < D, F > (pos:Position, outcome:Outcome < D, F > ):D {
		return 
			switch (outcome) {
				case Success(d): d;
				case Failure(f): pos.error(f);
			}
	}
	
	static public function asCurrent(pos:Position) {
		return PosContext.enter(pos);
	}
	
	static public function makeBlankType(pos:Position):ComplexType {
		return TypeTools.toComplex(Context.typeof(macro null));
	}
	
	static public inline function getPos(pos:Position) {
		return 
			if (pos == null) 
				PosContext.get();
			else
				pos;
	}
	static public function errorExpr(pos:Position, error:Dynamic) {
		return Bouncer.bounce(function ():Expr {
			return PosTools.error(pos, error);
		}, pos);		
	}
	static public inline function error(pos:Position, error:Dynamic):Dynamic {
		return Context.error(Std.string(error), pos);
	}
	static public inline function warning<A>(pos:Position, warning:Dynamic, ?ret:A):A {
		Context.warning(Std.string(warning), pos);
		return ret;
	}
	///used to easily construct failed outcomes
	static public function makeFailure<A, Reason>(pos:Position, reason:Reason):Outcome<A, MacroError<Reason>> {
		return Failure(new MacroError(reason, pos));
	}
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
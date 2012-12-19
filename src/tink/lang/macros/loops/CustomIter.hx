package tink.lang.macros.loops;

import haxe.macro.Expr;

typedef CustomIter = {
	init: Array<Expr>,
	hasNext: Expr,
	next: Expr
}
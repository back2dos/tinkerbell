package tink.macro.build;

import haxe.macro.Expr;

typedef Meta = { 
	name : String, 
	params : Array<Expr>, 
	pos : Position 
};
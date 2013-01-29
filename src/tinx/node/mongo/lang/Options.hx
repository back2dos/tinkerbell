package tinx.node.mongo.lang;

import haxe.macro.Expr;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

typedef Options = {
	//TODO: add sorting
	?limit: { skip: ExprOf<Int>, count: ExprOf<Int> }
}

private class Parser {
	public var options:Options;
	public function new(options:Array<Expr>) {
		this.options = { };
		for (o in options) 
			parse(o);
	}
	function parse(option:Expr) {
		switch (option.expr) {
			case EBinop(OpInterval, skip, count):
				if (options.limit != null)
					option.reject('limits already set');
				else {
					for (e in [skip, count])
						ECheckType(e, macro : Int).at(e.pos).typeof().sure();
					options.limit = { skip: skip, count: count };
				}
			default:
				option.reject();
		}
	}
}
private class Generator {
	static public function gen(o:Options) {
		var ret = [];
		function field(name, expr)
			ret.push( { field: name, expr: expr } );
		if (o.limit != null) {
			field('skip', o.limit.skip);
			field('limit', o.limit.count);
		}
		return EObjectDecl(ret).at();
	}
}
class OptionsTools {
	static function parse(options) {
		return new Parser(options).options;
	}
	static public function processOptions(options, info:TypeInfo) 
		return Generator.gen(parse(options))
}
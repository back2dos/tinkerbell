package tinx.node.mongo.lang;

import haxe.macro.Expr;

typedef Plugin<In, IR, Out> = {
	function parse(input:In):IR;
	function typeCheck(rep:IR, t:TypeInfo):Out;
	function generate(rep:IR):Expr;
}

class Compiler {
	static public function compile<In, IR, Out>(c:Plugin<In, IR, Out>, input:In, t) {
		var rep = c.parse(input);
		return {
			type: if (t == null) null else c.typeCheck(rep, t),
			expr: c.generate(rep)
		}
	}
}
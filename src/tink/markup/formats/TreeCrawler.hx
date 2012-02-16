package tink.markup.formats;

import haxe.macro.Expr;
using Lambda;
using tink.macro.tools.MacroTools;

/**
 * ...
 * @author back2dos
 */

typedef Plugin = {
	function init(pos:Position):Null<Expr>;
	function finalize(pos:Position):Null<Expr>;
	function transform(e:Expr, yield:Expr->Expr):Expr;
	function postprocess(e:Expr):Expr;
}
 
class TreeCrawler {
	var plugin:Plugin;
	function new(plugin) {
		this.plugin = plugin;
	}
	function transform(e:Expr) {
		return plugin.postprocess([
			plugin.init(e.pos),
			yield(e),
			plugin.finalize(e.pos)
		].filter(function (e) return e != null).toBlock(e.pos));
	}
	function yield(e:Expr):Expr {
		return 
			if (e == null) e;
			else
				switch (e.expr) {
					case EParenthesis(expr): 
						EParenthesis(yield(expr)).at(e.pos);
					case EUntyped(expr): 
						EUntyped(yield(expr)).at(e.pos);
					case EIf(cond, cons, alt), ETernary(cond, cons, alt):
						cond.cond(yield(cons), yield(alt), e.pos);
					case EFor(it, expr):
						EFor(it, yield(expr)).at(e.pos);
					case EWhile(cond, body, normal):
						EWhile(cond, yield(body), normal).at(e.pos);
					default:
						plugin.transform(e, yield);
				}
	}
	static public function build(e:Expr, plugin:Plugin) {
		return new TreeCrawler(plugin).transform(e);
	}
}
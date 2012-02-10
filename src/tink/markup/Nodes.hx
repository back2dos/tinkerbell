package tink.markup;
import haxe.macro.Expr;
import tink.macro.tools.AST;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
using tink.markup.Helpers;
/**
 * ...
 * @author back2dos
 */

class Nodes {
	var tmp:String;
	var target:Expr;
	var count:Int;
	public function new() {
		this.count = 0;
	}
	public function init(pos) {
		tmp = String.tempName();
		target = tmp.resolve(pos);
		return tmp.define(AST.build(Xml.createDocument()), pos);
	}
	public function finalize(pos) {
		return target;
	}
	public function postprocess(e) {
		return ECheckType(e, 'Xml'.asTypePath()).at(e.pos);
	}
	public function transform(e:Expr, yield:Expr->Expr) {
		return
			switch (e.typeof()) {
				case Success(_): addChild(e);
				case Failure(_): 
					switch (OpAssign.get(e)) {
						case Success(op):
							setAttr(op.e1.getName().data(), op.e2, op.pos);
						default:
							switch (e.expr) {
								case ECall(target, params): 
									bounceNode(target, params, yield, e.pos);
								default: 
									switch (OpLt.get(e)) {
										case Success(op): 
											bounceNode(op.e1, [op.e2], yield, e.pos);
										default: 
											bounceNode(e, [], yield, e.pos);
									}
							}
					}
			}
	}	
	function bounceNode(node, payload, yield, pos) {
		return callback(buildNode, node, payload, yield).bounce(pos);
	}
	function buildNode(node:Expr, payload:Array<Expr>, yield:Expr -> Expr) {
		var name = node.annotadedName(payload.unshift);
		var ret = [tmp.define(AST.build(Xml.createElement(Std.format("eval__name")), node.pos))];
		for (p in payload)
			for (p in p.interpolate())
				ret.push(yield(p));
		ret.push(target);
		return addChild(ret.toBlock(node.pos));
	}
	function addChild(e:Expr):Expr {
		if (e.getString().isSuccess()) 
			e = AST.build(Std.format($e));
		
		return AST.build({
			var tmp:Dynamic = $e;
			if (Std.is(tmp, Xml)) 
				$target.addChild(tmp);
			else 
				$target.addChild(Xml.createPCData(tmp));
		}, e.pos);
	}
	function stringifyExpr(e:Expr) {
		return 
			if (e.getString().isSuccess()) 
				AST.build(Std.format($e));
			else 
				e.stringify();
	}
	function setAttr(name:String, value:Expr, pos:Position) {
		return AST.build($target.set(Std.format("eval__name"), $(stringifyExpr(value))), pos);
	}
}
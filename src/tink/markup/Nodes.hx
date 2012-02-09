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
	public function new() {
		
	}
	public function init(pos) {
		tmp = String.tempName();
		target = tmp.resolve(pos);
		return tmp.define(AST.build(Xml.createDocument()), pos);
	}
	public function finalize(pos) {
		return target;
	}
	static var XML = 'Xml'.asTypePath();
	public function transform(e:Expr, yield:Expr->Expr) {
		return
			switch (e.typeof()) {
				case Success(_): addChild(e);
				case Failure(_): 
					switch (OpAssign.get(e)) {
						case Success(op):
							setAttr(op.e1.getName().data(), op.e2, op.pos);
						default:
							addChild(
								switch (e.expr) {
									case ECall(target, params): 
										buildNode(target, params, yield);
									default: 
										switch (OpLt.get(e)) {
											case Success(op): 
												buildNode(op.e1, [op.e2], yield);
											default: 
												buildNode(e, [], yield);
										}
								}
							);
					}
			}
	}	
	
	function buildNode(node:Expr, payload:Array<Expr>, yield:Expr -> Expr) {
		var name = node.annotadedName(payload.unshift);
		var ret = [tmp.define(AST.build(Xml.createElement(Std.format("eval__name")), node.pos))];
		for (p in payload)
			ret.push(yield(p));
		ret.push(target);
		return ret.toBlock(node.pos);
	}
	function addChild(e:Expr) {
		if (!e.is(XML)) 
			e = AST.build(Xml.createPCData($(stringifyExpr(e))), e.pos);
		return 
			if (target == null) e;
			else
				AST.build($target.addChild($e), e.pos);
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
package tink.markup.formats;

import haxe.macro.Expr;
import tink.macro.tools.AST;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
using tink.markup.formats.Helpers;
/**
 * ...
 * @author back2dos
 */

class Nodes {
	//TODO: unify with Fast as far as possible. For example transform (which does the most work anyway) is almost identical
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
		return xml(e);
	}
	static var XML = 'Xml'.asComplexType();
	static var STRING = 'String'.asComplexType();
	function xml(e:Expr):Expr {
		return ECheckType(e, XML).at(e.pos);
	}
	public function transform(e:Expr, yield:Expr->Expr) {
		return
			switch (e.typeof()) {
				case Success(_): addChild(e);
				case Failure(_): 
					switch (OpAssign.get(e)) {
						case Success(op):
							var ret = [];
							switch (op.e1.getName()) {
								case Success(name): setAttr(name, op.e2, op.pos, ret.push);
								default:
									switch (op.e1.expr) {
										case EArrayDecl(exprs):
											for (e in exprs) {
												var name = e.getName().sure();
												setAttr(name, op.e2.field(name, e.pos), e.pos, ret.push);
											}
										default: 
											op.e1.reject();
									}
							}							
							return ret.toBlock(op.pos);
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
		ret.push(xml(target));
		return addChild(ret.toBlock(node.pos));
	}
	function isSelfmadeNode(e:Expr) {
		return
			switch (e.expr) {
				case EBlock(exprs):
					switch (exprs[exprs.length - 1].expr) {
						case ECheckType(_, t): Type.enumEq(t, XML);
						default: false;
					}
				default: false;	
			}		
	}
	function addChild(e:Expr):Expr {
		return 
			if (isSelfmadeNode(e)) 
				AST.build($target.addChild($e), e.pos);
			else if (e.is(XML)) {
				throw ('found XML!!!');
				AST.build($target.addChild(e), e.pos);
			}
			else 
				AST.build($target.addChild(Xml.createPCData($(stringifyExpr(e)))), e.pos);
	}
	function stringifyExpr(e:Expr) {
		return 
			if (e.getString().isSuccess()) 
				AST.build(Std.format($e));
			else 
				e.stringify();
	}
	function setAttr(name:String, value:Expr, pos:Position, yield:Expr->Dynamic) {
		yield(AST.build($target.set(Std.format("eval__name"), $(stringifyExpr(value))), pos));
	}
}
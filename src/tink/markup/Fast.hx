package tink.markup;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Format;
import tink.macro.tools.AST;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
using tink.markup.Helpers;
/**
 * ...
 * @author back2dos
 */

private enum Kind {
	Prop;
	Child;
	Conflict;
	None;
}
class Fast {
	var out:Expr;
	public function new() {}
	public function init(pos:Position) {
		var name = String.tempName();
		out = name.resolve(pos);
		return name.define(AST.build(new StringBuf()), pos);
	}
	public function postprocess(e) {
		return e;
	}
	public function finalize(pos:Position) {
		return out;
	}
	inline function prints(s:String, ?pos) {
		return print(s.toExpr(pos));
	}
	function print(e:Expr) {
		var ret = [];
		for (e in e.interpolate()) 
			ret.push(AST.build($out.add($(e.stringify())), e.pos));
		return
			if (ret.length == 1) ret[0];
			else 
				ret.toBlock(e.pos);
	}
	function getKind(e:Expr):Kind {
		return
			if (e == null) None;
			else if (OpAssign.get(e).isSuccess()) Prop;
			else 
				switch (e.expr) {
					case EParenthesis(e), EUntyped(e): 
						getKind(e);
					case EIf(cond, cons, alt), ETernary(cond, cons, alt):
						unify(getKind(cons), getKind(alt)); 
					case EFor(it, expr):
						getKind(expr);
					case EWhile(cond, body, normal):
						getKind(body);
					default: Child;
				}
	}
	function unify(k1:Kind, k2:Kind):Kind {
		return
			if (k1 == None) k2;
			else if (k2 == None) k1;
			else if (k1 == k2) k1;
			else Conflict;
	}
	function bounceNode(atom, payload, yield, pos) {
		return callback(buildNode, atom, payload, yield).bounce(pos);
	}
	function buildNode(atom:Expr, payload:Array<Expr>, yield:Expr->Expr) {
		var name = atom.annotadedName(payload.unshift);
		return
			if (payload.length == 0) prints('<' + name + '/>');
			else {
				var props = [],
					children = [],
					ret = [];
					
				for (p in payload) 
					switch (getKind(p)) {
						case Prop: props.push(p);
						case Child: children = children.concat(p.interpolate());
						case None: p.reject('expression seems not to yield an attribute or a child');
						case Conflict: p.reject('you can only either set an attribute or a child');
					}
				
				if (children.length == 0) {
					ret.push(prints('<' + name));
					for (p in props)
						ret.push(yield(p));
					ret.push(prints('/>'));
				}
				else {
					if (props.length == 0)
						ret.push(prints('<' + name + '>'));
					else {
						ret.push(prints('<' + name));
						for (p in props)
							ret.push(yield(p));
						ret.push(prints('>'));
					}
					for (c in children)
						ret.push(yield(c));
					ret.push(prints('</' + name + '>'));					
				}
				ret.toBlock();
			}
	}
	function setAttr(name:String, value:Expr, pos, yield:Expr->Dynamic) {
		switch (value.getString()) {
			case Success(s):
				yield(prints(' '+name + '="' + s + '"', pos));
			default:
				yield(prints(' ' + name + '="', pos));
				yield(print(value));
				yield(prints('"', pos));
		}
	}
	public function transform(e:Expr, yield:Expr->Expr) {
		return
			switch (e.typeof()) {
				case Success(_): print(e);
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
												var name = e.getName().data();
												setAttr(name, op.e2.field(name, e.pos), e.pos, ret.push);
											}
										default: 
											op.e1.reject();
									}
							}
							ret.toBlock(op.pos);
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
}
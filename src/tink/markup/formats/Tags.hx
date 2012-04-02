package tink.markup.formats;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Format;
import tink.macro.tools.AST;

/**
 * ...
 * @author back2dos
 */
using tink.macro.tools.MacroTools;
using StringTools;
using tink.core.types.Outcome;
using Lambda;

private enum Kind {
	Prop;
	Child;
	Conflict;
	None;
}
private typedef Plugin = {
	function init(pos:Position):Null<Expr>;
	function finalize(pos:Position):Null<Expr>;
	function defaultTag(pos:Position):Expr;
	function postprocess(e:Expr):Expr;
	function setProp(attr:String, value:Expr, pos:Position):Expr;
	function addString(s:String, pos:Position):Expr;
	function addChild(e:Expr, ?t:Type):Expr;
	function buildNode(nodeName:Expr, props:Array<Expr>, children:Array<Expr>, pos:Position, yield:Expr->Expr):Expr;
}

class Tags {
	var plugin:Plugin;
	public function new(plugin) {
		this.plugin = plugin;
		var e1:Expr = AST.build([1, 2, 3, 4]),
			e2:Expr = AST.build([1, 2, 3, 4]);
	}
	public function init(pos:Position):Null<Expr> return plugin.init(pos)
	public function finalize(pos:Position):Null<Expr> return plugin.finalize(pos)
	public function postprocess(e:Expr):Expr return plugin.postprocess(e)

	function getTag(src:Expr) {
		return
			switch (src.getIdent()) {
				case Success(s):
					if (s.startsWith('$'))
						s.substr(1).toExpr(src.pos).asSuccess();
					else
						src.asFailure();
				default:
					switch (src.getString()) {
						case Success(_): 
							'Std.format'.resolve(src.pos).call([src], src.pos).asSuccess();
						default:
							src.asFailure();
					}
			}
	}
	function annotadedName(atom:Expr, yield:Expr->Dynamic) {
		return
			switch (atom.expr) {
				case EArrayDecl(values):
					if (values.length != 1) 
						atom.reject();
					getAnnotations(values[0], yield);
					plugin.defaultTag(atom.pos).asSuccess();
					
				case EArray(e1, e2):
					getAnnotations(e2, yield);
					getTag(e1);
				default:
					getTag(atom);
			}
		
	}
	function getAnnotations(src:Expr, yield:Expr->Dynamic) {
		var cls = new List();
		while (src != null) 
			switch (src.expr) {
				case EField(e, f), EType(e, f): 
					cls.push(f);
					src = e;
				default:
					switch (src.getIdent()) {
						case Success(s):
							//TODO: can call to plugin here directly
							if (s.charAt(0) == '$')
								yield(AST.build(id = $(s.substr(1).toExpr(src.pos)), src.pos));
							else 
								cls.push(s);
								
							if (cls.length > 0)
								yield(AST.build('class' = $(cls.join(' ').toExpr(src.pos)), src.pos));
								
							src = null;
						default:
							src.reject();
					}
			}
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
					case ESwitch(e, cases, edef):
						var ret = getKind(edef);
						for (c in cases)
							ret = unify(ret, getKind(c.expr));
						ret;
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
	function build(of:Expr, params:Array<Expr>, src:Expr, yield:Expr->Expr):Expr {
		var props = [];
		return 
			switch (annotadedName(of, props.push)) {
				case Success(nodeName):
					var children = [];
					for (p in params) 
						switch (getKind(p)) {
							case Prop: props.push(p);
							case Child: children = children.concat(interpolate(p));
							case None: p.reject('expression seems not to yield an attribute or a child');
							case Conflict: p.reject('you can only either set an attribute or a child');
						}
					plugin.buildNode(nodeName, props, children, src.pos, yield);
				
				default:
					plugin.addChild(src);
			}
	}
	
	public function transform(e:Expr, yield:Expr->Expr):Expr {
		return
			switch (e.typeof()) {
				case Success(_): 
					switch (e.getString()) {
						case Success(s): plugin.addString(s, e.pos);
						default: plugin.addChild(e);
					}
				case Failure(_): 
					switch (e.getBinop()) {
						case Success(op):
							switch (op.op) {
								case OpAssign:
									var ret = [];
									switch (op.e1.getName()) {
										case Success(name): 
											ret.push(plugin.setProp(name, op.e2, op.pos));
										default:
											switch (op.e1.expr) {
												case EArrayDecl(exprs):
													for (e in exprs) {
														var name = e.getName().sure();
														ret.push(plugin.setProp(name, op.e2.field(name, e.pos), e.pos));
													}
												default: 
													op.e1.reject();
											}
									}							
									if (ret.length == 1) ret[0];
									else
										ret.toBlock(op.pos);
								case OpLt:
									build(op.e1, [op.e2], e, yield);
								default:
									build(e, [], e, yield);
							}
						default:				
							switch (e.expr) {
								case ECall(target, params): 
									build(target, params, e, yield);
								default: 
									build(e, [], e, yield);
							}
					}
			}
	}
	static function interpolate(e:Expr) {
		return
			if (e.getString().isSuccess()) {				
				var f = Context.parse;
				untyped Context.parse = function (e, pos) return EParenthesis(f(e, pos)).at(pos);//don't do this at home!
				var ret = [];
				e = Format.format(e);
				function yield(e:Expr) 
					ret.push(
						switch (e.expr) {
							case EParenthesis(e): e;
							default: e;
						}
					);
				while (true) 
					switch (OpAdd.get(e)) {
						case Success(op):
							e = op.e1;
							yield(op.e2);
						default: 
							yield(e);
							break;
					}
				ret.reverse();
				untyped Context.parse = f;
				ret;
			}
			else [e];
	}	
}
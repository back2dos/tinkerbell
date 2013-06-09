package tink.markup.formats;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Format;

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
	}
	public function init(pos:Position):Null<Expr> return plugin.init(pos);
	public function finalize(pos:Position):Null<Expr> return plugin.finalize(pos);
	public function postprocess(e:Expr):Expr return plugin.postprocess(e);

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
							interpolate(src).fold(function (e1, e2) return macro $e1 + $e2, macro '').asSuccess();
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
				case EField(e, f):
					cls.push(f);
					src = e;
				default:
					switch (src.getIdent()) {
						case Success(s):
							//TODO: can call to plugin here directly
							if (s.charAt(0) == '$') {
								var value = s.substr(1).toExpr(src.pos);
								yield((macro id = $value).finalize(src.pos));
							}
							else 
								cls.push(s);
								
							if (cls.length > 0) {
								var value = cls.join(' ').toExpr(src.pos);
								yield((macro 'class' = $value).finalize(src.pos));
							}
								
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
					case EIf(_, cons, alt), ETernary(_, cons, alt):
						unify(getKind(cons), getKind(alt)); 
					case EFor(_, expr):
						getKind(expr);
					case EWhile(_, body, _):
						getKind(body);
					case ESwitch(_, cases, edef):
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
			//switch (e.typeof()) {
				//case Success(_): 
					//switch (e.getString()) {
						//case Success(s): plugin.addString(s, e.pos);
						//default: plugin.addChild(e);
					//}
			switch (e.getString()) {
				case Success(s): plugin.addString(s, e.pos);
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
	static function interpolate(e:Expr):Array<Expr> {
		return
			switch (e.getString()) {
				case Success(str):
					var pos = Context.getPosInfos(e.pos);
					var min = pos.min;
					pos.min++;
					
					function make(size) {
						pos.max = pos.min + size;
						var p = Context.makePosition(pos);
						pos.min += size;
						return p;
					}
					var ret = [];
					var add = ret.push,
						i = 0, 
						start = 0,
						max = str.length;
						
					while( i < max ) {
						if( StringTools.fastCodeAt(str,i++) != '$'.code )
							continue;
						var len = i - start - 1;
						if( len > 0 )
							add({ expr : EConst(CString(str.substr(start,len))), pos : make(len) });
						pos.min++;
						start = i;
						var c = StringTools.fastCodeAt(str, i);
						if( c == '{'.code ) {
							var count = 1;
							i++;
							while( i < max ) {
								var c = StringTools.fastCodeAt(str,i++);
								if( c == "}".code ) {
									if( --count == 0 ) break;
								} else if( c == "{".code )
									count++;
							}
							if( count > 0 )
								Context.error("Closing brace not found",make(1));
							pos.min++;
							start++;
							var len = i - start - 1;
							var expr = str.substr(start, len);
							add(Context.parseInlineString(expr, make(len)));
							pos.min++;
							start++;
						} else if( (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code) || c == '_'.code ) {
							i++;
							while( true ) {
								var c = StringTools.fastCodeAt(str, i);
								if( (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code) || (c >= '0'.code && c <= '9'.code) || c == '_'.code )
									i++;
								else
									break;
							}
							var len = i - start;
							var ident = str.substr(start, len);
							add( { expr : EConst(CIdent(ident)), pos : make(len) } );
						} else if( c == '$'.code ) {
							start = i++;
							continue;
						} else {
							start = i - 1;
							continue;
						}
						start = i;
					}
					var len = i - start;
					if( len > 0 )
						add( { expr : EConst(CString(str.substr(start, len))), pos : make(len) } );
						
					ret;
				default: [e];
			}
	}
}
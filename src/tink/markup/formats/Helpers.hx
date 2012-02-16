package tink.markup.formats;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Format;
import tink.macro.tools.AST;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

/**
 * ...
 * @author back2dos
 */

class Helpers {
	static public function annotadedName(atom:Expr, yield:Expr->Dynamic) {
		return
			switch (atom.expr) {
				case EArrayDecl(values):
					if (values.length != 1) 
						atom.reject();
					getAnnotations(values[0], yield);
					'div';
				case EArray(e1, e2):
					getAnnotations(e2, yield);
					e1.getIdent().data();
				default:
					atom.getIdent().data();
			}
		
	}
	static function getAnnotations(src:Expr, yield:Expr->Dynamic) {
		var cls = new List();
		while (src != null) 
			switch (src.expr) {
				case EField(e, f), EType(e, f): 
					cls.push(f);
					src = e;
				default:
					switch (src.getIdent()) {
						case Success(s):
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
	static var STRING = 'String'.asTypePath();
	static function stringifyVar(e:Expr) {
		return
			if (e.is(STRING)) e;
			else 
				AST.build(Std.string($e), e.pos);
	}
	static public function stringify(e:Expr) {
		var id = e.getIdent();
		return
			if (id.map(isLiteral).equals(true)) 
				id.data().toExpr(e.pos);
			else switch (e.expr) {
				case EConst(c):
					switch (c) {
						case CInt(s), CFloat(s), CString(s): s.toExpr(e.pos);
						default: stringifyVar(e);
					}
				default: 
					stringifyVar(e);
			}
	}
	static public function interpolate(e:Expr) {
		return
			if (e.getString().isSuccess()) {				
				var f = Context.parse;
				untyped Context.parse = function (e, pos) return EParenthesis(f(e, pos)).at(pos);//don't do this at home!
				var ret = [];
				e = Format.format(e);
				while (true) 
					switch (OpAdd.get(e)) {
						case Success(op):
							e = op.e1;
							ret.push(op.e2);
						default: 
							ret.push(e);
							break;
					}
				ret.reverse();
				untyped Context.parse = f;
				ret;
			}
			else [e];
	}
	static var isLiteral = {
		var h = new Hash();
		for (l in 'null,true,false'.split(',')) 
			h.set(l, true);
		h.exists;
	}		
}
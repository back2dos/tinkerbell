package tink.macro.tools;

import haxe.macro.Context;
import haxe.macro.Expr;
using Lambda;
using tink.macro.tools.ExprTools;

class Printer {
	static var binops = '+,*,/,-,=,==,!=,>,>=,<,<=,&,|,^,&&,||,<<,>>,>>>,%,NONE,...,=>'.split(',');
	static var unops = '++,--,!,-,~'.split(',');
	static public function binoperator(b:Binop) {
		return 
			switch (b) {
				case OpAssignOp(op):
					binoperator(op) + '=';
				default:
					binops[Type.enumIndex(b)];
			}			
	}
	static public function unoperator(u:Unop)
		return unops[Type.enumIndex(u)];
	static public function binop(?indent:String = '', b:Binop, e1:Expr, e2:Expr):String {
		function rec(e)
			return printExpr(indent, e);		
		return '(' + rec(e1) + ' ' + binoperator(b) + ' ' + rec(e2) +')';
	}
	static public function printExprList(indent:String, list:Iterable<Expr>, ?sep = ', ', ?border:Array<String>):String {
		return printList(list.map(printExpr.bind(indent)), sep, border);
	}
	static public function printList(list:Iterable<String>, ?sep = ', ', ?border:Array<String>) {
		if (border == null) border = '()'.split('');
		return border[0] + list.list().join(sep) + border[1];			
	}
	static public function printPath(indent:String, p:TypePath) {
		var a = p.pack.copy();
		a.push(p.name);
		if (p.sub != null) a.push(p.sub);
		var ret = a.join('.');
		if (p.params.length > 0) {
			var a = [];
			for (p in p.params)
				a.push(printParam(indent, p));
			ret += '<' + a.join(', ') + '>';
		}
		return ret;
	}
	static public function printParam(indent:String, t:TypeParam) {
		return
			switch (t) {
				case TPType(t): printType(indent, t);
				case TPExpr(e): printExpr(indent, e);
			}
	}
	static public function printType(indent:String, t:ComplexType) {
		return
			switch (t) {
				case TOptional(t): '?' + printType(indent, t);
				case TPath(p): 
					printPath(indent, p);
				case TFunction(args, ret):
					if (args.length == 0) 'Void -> ' + printType(indent, ret);
					else args.concat([ret]).map(printType.bind(indent)).array().join(' -> '); 
				case TAnonymous(fields): 
					printFields(indent, fields);
				case TParent(t): 
					'(' + printType(indent, t) + ')';
				case TExtend(p, fields):
					printFields(indent, fields, p);
			}
	}
	static public function printFields(indent:String, fields:Array<Field>, ?extend:TypePath) {
		var ret = '{ ';
		if (extend != null) ret += '> ' + printPath(indent, extend) + '; ';
		var a = [];
		for (field in fields)
			a.push(printField('\t' + indent, field));
		if (a.length > 0)
			ret += '\n\t' + indent + a.join(';\n\t' + indent) + ';\n' + indent;
		return ret +'}';
	}
	static public function printFunction(f:Function, ?name:String, ?indent = '') {
		function rec(e)
			return printExpr(indent, e);
		
		var ret = 'function ';
		if (name != null) ret += name;
		var args = [];
		for (arg in f.args) {
			var s = if (arg.opt) '?' else '';
			s += arg.name;
			s += typify(indent, arg.type);
			if (arg.value != null) s += ' = ' + rec(arg.value);
			args.push(s);
		}
		var params = [];
		for (p in f.params) {
			var constraints = [];
			for (c in p.constraints)
				constraints.push(printType(indent, c));
			var ret = p.name;
			ret +=
				switch (constraints.length) {
					case 0: '';
					case 1: ':' + constraints[0];
					default: ':(' + constraints.join(', ') + ')';
				}
			params.push(ret);
		}
		if (params.length > 0)
			ret += '<' + params.join(', ') + '>';
		ret += '(' + args.join(', ') + ')';
		if (f.ret != null) 
			ret += ':' + printType(indent, f.ret);
		if (f.expr != null)
			ret += ' ' + rec(f.expr);
		return ret;
	}
	static public function printInitializer(indent:String, e:Expr) {
		return 
			if (e == null) '';
			else ' = ' + printExpr(indent, e);
	}
	static function typify(indent:String, t:ComplexType) {
		return 
			if (t == null) '';
			else ':' + printType(indent, t);
	}
	static public function printField(indent:String, field:Field) {
		var ret = '';
		if (field.access != null)
			for (a in field.access)
				ret += Type.enumConstructor(a).substr(1).toLowerCase() + ' ';
		ret +=
			switch (field.kind) {
				case FVar(t, e): 'var ' + field.name + typify(indent, t) + printInitializer(indent, e);
				case FProp(get, set, t, e): 'var ' + field.name + '(' + get + ', ' + set + ')' + typify(indent, t) + printInitializer(indent, e);
				case FFun(f): printFunction(f, field.name, indent);
			}
		return ret;
	}
	static public function print(e:Expr):String {
		return printExpr('', e);
	}
	static public function printExpr(indent:String, e:Expr):String {
		function rec(e)
			return printExpr(indent, e);
		return 
			if (e == null) '#NULL';
			else if (e.expr == null) '#MALFORMED';
			else
				switch (e.expr) {
					case EConst(c):
						switch (c) {
							case CInt(s), CFloat(s), CIdent(s): s;
							case CString(s): '"' + s + '"';
							case CRegexp(r, opt): '~/' + r + '/' + opt;
						}
					case EVars(vars):
						var ret = [];
						for (v in vars) 
							ret.push(v.name + typify(indent, v.type) + printInitializer(indent, v.expr));
						'var ' + ret.join(', ');
					case ECheckType(e, t): '(' + rec(e) + '/* ' + typify(indent, t) + ' */)';
					case ECast(e, t):
						'cast(' + rec(e) + ((t == null) ? '' : ', ' + printType(indent, t)) + ')';
					case EArray(e1, e2): 
						rec(e1) + '[' + rec(e2) + ']';
					case EField(e, field):
						rec(e) + '.' + field;
					case EParenthesis(e):
						'(' + rec(e) + ')';
					case ECall(e, params):
						rec(e) + printExprList(indent, params);
					case EIf(econd, eif, eelse):
						'if (' + rec(econd) + ') ' + rec(eif) + 
							if (eelse == null) 
								'' 
							else 
								('\n' + indent + 'else ' + rec(eelse));
					case EBlock(exprs):
						if (exprs.length == 0) 
							'{}';
						else
							printExprList(indent + '\t', exprs, ';\n\t' + indent, ['{\n\t' + indent, ';\n' + indent + '}']);
					case EIn(e1, e2):
						rec(e1) + ' in ' + rec(e2);
					case EFor(it, expr):
						'for (' + rec(it) + ')\n\t' + indent + printExpr(indent + '\t', expr);
					case EWhile(econd, e, normalWhile):
						if (normalWhile)
							'while (' + rec(econd) + ') ' + rec(e);
						else 
							'do ' + rec(e) + '\n' + indent + 'while (' + rec(econd) + ')';
					case EBreak: 'break';
					case EContinue: 'continue';
					case EUntyped(e): '(untyped ' + rec(e) + ')';
					case EThrow(e): 'throw ' + rec(e);
					case EReturn(e): 'return' + if (e == null) '' else (' ' + rec(e));
					case EDisplay(e, isCall):
						rec(e) + (isCall ? '(/*DISPLAY*/)' : '/*.DISPLAY*/');
					case EDisplayNew(t):
						'new ' + printPath(indent, t) + '(/*DISPLAY*/)';
					case ETernary(econd, eif, eelse):
						'((' + rec(econd) + ') ? ' + rec(eif) + ' : ' + rec(eelse) + ')';
					case ESwitch(e, cases, edef):
						var ret = [];
						for (c in cases)
							ret.push(
								'case ' + printExprList(indent, c.values, ['', '']) 
								+ (if (c.guard == null) '' else ' if '+rec(c.guard))
								+ ': ' + printExpr(indent + '\t', c.expr));
						if (edef != null) 
							ret.push('default: ' + rec(edef));
						'switch (' + rec(e) + ') {\n\t' + indent + ret.join('\n\t' + indent) + '\n' + indent + '}';
					case EUnop(op, postFix, e):
						var op = unops[Type.enumIndex(op)];
						var e = rec(e);
						var inner = 
							if (postFix) 
								e + op;
							else
								op + e;
						'(' + inner + ')';
					case ETry(e, catches):
						var ret = [];
						for (c in catches)
							ret.push('catch (' + c.name +':' + printType(indent, c.type) + ') ' + rec(c.expr));
						'try ' + rec(e) + '\n' + indent + ret.join('\n' + indent);
					case ENew(t, params):
						'new ' + printPath(indent, t) + printExprList(indent, params);
					case EBinop(op, e1, e2):
						binop(indent, op, e1, e2);
					case EArrayDecl(values):
						printExprList(indent, values, '[]'.split(''));
					case EObjectDecl(fields):
						var ret = [];
						for (field in fields) 
							ret.push(field.field + ' : ' + rec(field.expr));
						printList(ret, '{}'.split(''));
					case EFunction(name, f): 
						printFunction(f, name, indent);
					case EMeta(s, e):
						'@' + s.name + printExprList(indent, s.params) + ' ' + rec(e);
					//default: '#UNSUPPORTED_' + Type.enumConstructor(e.expr);
			}
	}		
}
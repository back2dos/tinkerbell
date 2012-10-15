package tink.macro.tools;

#if (macro || neko)
/**
 * ...
 * @author back2dos
 */
import haxe.macro.Context;
import haxe.macro.Expr;
import tink.core.types.Outcome;

using StringTools;
using tink.core.types.Outcome;
using tink.macro.tools.MacroTools;

class AST {
	///returns an expression that evaluates to the ast of the given expression, while performing a number of substitutions
	@:macro static public function build(expr:Expr, ?pos:Expr):ExprRequire<Expr> {
		return (new Builder(pos)).transformExpr(expr);
	}	
}

private class Builder {
	var here:Expr;
	var varName:String;
	var posDecl:Expr;
	var temps:Hash<String>;
	var subst:Bool;
	static var NULL = EConst(CIdent('null'));
	public function new(pos:Expr, ?noSubst = false) {
		this.temps = new Hash();
		this.subst = !noSubst;
		var varName = String.tempName();
		var posExpr = 
			if (pos.getIdent().equals('null'))
				'haxe.macro.Context.currentPos'.resolve().call();
			else
				pos;
		this.posDecl = varName.define(posExpr);
		this.here = varName.resolve();
	}
	
	function transformEnum(value:Dynamic) {
		var params = Lambda.array(Lambda.map(Type.enumParameters(value), transform));
		var constr = Type.enumConstructor(value).resolve();
		return
			if (params.length > 0) 
				ECall(constr, params).at();
			else
				constr;			
	}
	public function transformExpr(e:Expr):Expr {
		return [
			posDecl,
			transform(e)
		].toBlock();
	}
	function isEval(s:String) {
		return
			if (subst && StringTools.startsWith(s.toLowerCase(), 'eval__'))
				Outcome.Success(s.substr(6));
			else
				Outcome.Failure();
	}
	function eval(value:ExprDef):ExprDef {
		return
			switch (value) {
				case EConst(c):
					switch (c) {
						case CIdent(id):
							if (subst && id.startsWith('$')) 
								EConst(CIdent(id.substr(1)));
							else null;
						default: null;
					}
				case ECall(e, args):
					if (subst && e.getIdent().equals('$')) {
						if (args.length != 1) 
							e.pos.error('eval requires one argument');
						else
							args[0].expr;
					}
					else null;
				default: null;
			}
	}
	function transformObject(value:Dynamic):Expr {
		var fields = [];
		for (field in Reflect.fields(value)) 
			fields.push({ 
				field: field, 
				expr: transform(Reflect.field(value, field)), 
			});
		return EObjectDecl(fields).at();
	}
	public function transform(value:Dynamic):Expr {
		return
			switch (Type.typeof(value)) {
				case TNull, TInt, TFloat, TBool:
					value.toExpr();
				case TObject:
					if (Std.is(value.expr, ExprDef)) {
						var e:Expr = value;
						var edef = eval(e.expr);
						if (edef == null) 
							{ pos: here, expr: transformEnum(e.expr) } .toFields();
						else 
							edef.at(e.pos);
					}
					else if (Std.is(value.access, Array)) {
						var f:Field = value;
						{
							name : transform(f.name),
							doc : transform(f.doc),
							access : transform(f.access),
							kind : transformEnum(f.kind),
							pos : here,
							meta : transform(f.meta),
						}.toFields();
					}
					else transformObject(value);
				case TClass(c):
					if (c == String) {
						switch (isEval(value)) {
							case Success(s):			
								s.resolve();
							default: 
								var s:String = value;
								if (s.startsWith('tmp')) {
									s = s.substr(3);
									if (temps.exists(s)) 
										s = temps.get(s);
									else 
										temps.set(s, s = String.tempName());
								}
								s.toExpr();
						}
					}
					else if (c == Array) {
						var value:Array<Dynamic> = value;
						var ret = [];
						for (entry in value)
							ret.push(transform(entry));
						EArrayDecl(ret).at();
					}
					else
						throw 'Cannot transform ' + Type.getClassName(c);
				case TEnum(e):
					if (e == ComplexType) {
						switch (cast(value, ComplexType)) {
							case TPath(tp): 
								if (subst && tp.name.startsWith('Eval__'))
									tp.name.substr(6).resolve();
								else 
									transformEnum(value);
							default: 
								transformEnum(value);
						}
					}
					else transformEnum(value);
				default:
					if (Std.string(value).startsWith('#pos')) here;
					else 
						throw 'Cannot transform ' + Std.string(value);
			}
	}			
}
#end
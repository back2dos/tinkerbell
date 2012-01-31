package tink.markup;

import haxe.macro.Expr;
#if neko
import tink.macro.tools.AST;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
using StringTools;
using Lambda;
#end
/**
 * ...
 * @author back2dos
 */

class MarkupBuilder {
	#if neko
	//var id:Expr;
	var plugin:Plugin;
	function new(plugin) {
		this.plugin = plugin;	
		//var id = counter++;
		//this.id = id.toExpr();
		//instances.set(id, this);
	}
	function transform(e:Expr):Expr {
		return switch (e.typeof()) {
			case Success(_): e;
			case Failure(_): callback(overload, e).bounce();
		}
	}
	function overload(e:Expr):Expr {
		return 
			switch (OpAssign.get(e)) {
				case Success(op): 
					var annotated = getAnnotated(op.e1);
					switch (op.e2.expr) {
						case EObjectDecl(fields):
							overloadTarget(annotated.expr, annotated.annotations, fields, [], op.pos);
						case ECall(fields, params):
							switch (fields.expr) {
								case EObjectDecl(fields):
									overloadTarget(annotated.expr, annotated.annotations, fields, params, op.pos);
								default: e;
							}
							
						default: e;
					}
				default: 
					switch (e.expr) {
						case ECall(target, params):
							var annotated = getAnnotated(target);
							overloadTarget(annotated.expr, annotated.annotations, [], params, e.pos);
						default: 
							getAtom(e);
					}
			}
	}	
	function getAtom(target:Expr) {
		return plugin.enter(target, transform);
	}
	function getAnnotations(e:Expr) {
		return e.toString().split('.');
	}
	function makeAnnotated(e:Expr, annotations:Array<String>, ?pos:Position) {
		return {
			expr: e,
			annotations: {
				values:annotations,
				pos: pos == null ? e.pos : pos
			}
		}
	}
	function getAnnotated(target:Expr) {
		return
			switch (target.expr) {
				case EArray(e1, e2): makeAnnotated(getAtom(e1), getAnnotations(e2));
				case EArrayDecl(values): 
					makeAnnotated(
						getAtom('null'.resolve(target.pos)),
						switch (values.length) {
							case 0: [];
							case 1: getAnnotations(values[0]);
							default: target.reject('one entry maximum');
						}
					);
				default: makeAnnotated(getAtom(target), []);
			}
	}
	function overloadTarget(target:Expr, annotations:Annotations, fields:Array<{field:String, expr:Expr}>, children:Array<Expr>, pos:Position) {
		var tmpName = String.tempName();
		var ret = [tmpName.define(target, target.pos)],
			id = tmpName.resolve(pos);
		if (annotations.values.length + fields.length > 0)
			ret.push(plugin.init(id, annotations, fields, pos));
			
		for (child in children)
			ret.push(add(id, child.pos, child));
		
		ret.push(id);
		return ret.toBlock(pos);
	}

	function add(parent:Expr, pos:Position, payload:Expr):Expr {
		function doAdd(e:Expr):Expr 
			return 
				if (e == null) null;
				else 
					plugin.add(parent, transform(e), pos);
					
		return
			switch (payload.expr) {
				case EIf(cond, cons, alt), ETernary(cond, cons, alt): 
					cond.cond(doAdd(cons), doAdd(alt), pos);
				case ESwitch(e, cases, edef):
					var ncases = [];
					for (c in cases)
						ncases.push( { values: c.values, expr: doAdd(c.expr) } );
					ESwitch(e, ncases, doAdd(edef)).at(pos);					
				case EParenthesis(e): 
					add(parent, pos, e);
				case EFor(it, expr):
					EFor(it, add(parent, pos, expr)).at(pos);
				case EWhile(cond, e, normal):
					EWhile(cond, add(parent, pos, e), normal).at(pos);
				case EBlock(exprs):
					exprs = exprs.copy();
					exprs.push(add(parent, pos, exprs.pop()));
					exprs.toBlock(pos);
				//ignored
					case EFunction(_, _), EVars(_): 
						payload;
				//rejected - none for now
					//payload.log().reject();
				//plain
					default:
						doAdd(payload);
			}
	}
	//static var counter = 0;
	//static var instances = new IntHash();
	static public function build(plugin:Plugin, source:Expr) {
		return new MarkupBuilder(plugin).transform(source);
	}
	#end	
	//@:macro static public function bounce(i:Int, e:Expr):Expr {
		//return instances.get(i).overload(e);
	//}
}
#if neko
	typedef Annotations = {
		values:Array<String>,
		pos:Position,
	}
	typedef Plugin = {
		function boot():Expr;
		function finalize(e:Expr, t:Expr->Expr):Expr;
		function enter(e:Expr, t:Expr->Expr):Expr;
		function exit():Expr;
		function init(target:Expr, annotations:Annotations, attributes:Array<{field:String, expr:Expr}>, pos:Position):Expr;
		function add(parent:Expr, child:Expr, pos:Position):Expr;
		function fix(wrong:Expr, reason:Dynamic, transformer:Expr->Expr):Expr;
	}
#end
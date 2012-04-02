package tink.markup.formats;

import haxe.macro.Expr;
import haxe.macro.Format;
import tink.macro.tools.AST;

using tink.macro.tools.MacroTools;
//using tink.core.types.Outcome;
using Lambda;
//using tink.markup.formats.Helpers;
/**
 * ...
 * @author back2dos
 */

class Nodes {
	var stack:List<String>;
	var target:Expr;
	public function new() {
		this.stack = new List();
	}
	function open() {
		var name = String.tempName();
		stack.push(name);
		target = name.resolve();
		return name;
	}
	function close() {
		var ret = stack.pop();
		var name = stack.first();
		target = 
			if (name == null) null;
			else 
				name.resolve();
		return ret.resolve();		
	}
	public function init(pos:Position):Null<Expr> {
		return open().define(AST.build(Xml.createDocument()), pos);
	}
	public function finalize(pos:Position):Null<Expr> {
		return close();
	}
	public function defaultTag(pos:Position):Expr {
		return 'div'.toExpr(pos);
	}
	public function postprocess(e:Expr):Expr {
		return AST.build($e.firstChild(), e.pos);
	}
	function stringifyProp(value:Expr):Expr {
		return
			switch (value.getString()) {
				case Success(_): 
					Format.format(value);
				default:
					if (value.is(STRING)) 
						value;
					else 
						AST.build(Std.string($value));
			}
	}
	public function setProp(attr:String, value:Expr, pos:Position):Expr {
		value = callback(stringifyProp, value).bounce();
		return AST.build($target.set("eval__attr", $value), pos);
	}
	function addChildNode(e:Expr):Expr {
		return AST.build($target.addChild($e), e.pos);
	}
	function doAddChild(target:Expr, e:Expr):Expr {
		return 
			if (e.is(XML))
				AST.build($target.addChild($e), e.pos);
			else if (e.is(STRING)) 
				AST.build($target.addChild(Xml.createPCData($e)), e.pos);
			else
				AST.build($target.addChild(Std.string(Xml.createPCData($e))), e.pos);
	}
	public function addChild(e:Expr, ?t:Type):Expr {
		return callback(doAddChild, target, e).bounce();
	}
	public function addString(s:String, pos:Position):Expr {
		return AST.build($target.addChild(Xml.createPCData('eval__s')), pos);
	}
	public function buildNode(nodeName:Expr, props:Array<Expr>, children:Array<Expr>, pos:Position, yield:Expr->Expr):Expr {
		var ret = [open().define(AST.build(Xml.createElement($nodeName), pos))];
		for (p in props)
			ret.push(yield(p));
		for (c in children)
			ret.push(yield(c));
		ret.push(close());
		return addChildNode(ret.toBlock(pos));
	}
	static var XML = 'Xml'.asComplexType();
	static var STRING = 'String'.asComplexType();
}
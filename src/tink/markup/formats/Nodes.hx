package tink.markup.formats;

import haxe.macro.Expr;
import haxe.macro.Format;

using tink.macro.tools.MacroTools;
using Lambda;

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
		return open().define((macro Xml.createDocument()).finalize(pos));
	}
	public function finalize(pos:Position):Null<Expr> {
		return close();
	}
	public function defaultTag(pos:Position):Expr {
		return 'div'.toExpr(pos);
	}
	public function postprocess(e:Expr):Expr {
		return (macro $e.firstChild()).finalize(e.pos);
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
						macro Std.string($value);
			}
	}
	public function setProp(attr:String, value:Expr, pos:Position):Expr {
		value = stringifyProp.bind(value).bounce();
		var attr = attr.toExpr(pos);
		return (macro $target.set($attr, $value)).finalize(pos);
	}
	function addChildNode(e:Expr):Expr {
		return (macro $target.addChild($e)).finalize(e.pos);
	}
	function doAddChild(target:Expr, e:Expr):Expr {
		return (
			if (e.is(XML))
				macro $target.addChild($e)
			else if (e.is(STRING)) 
				macro $target.addChild(Xml.createPCData($e))
			else
				macro $target.addChild(Xml.createPCData(Std.string($e)))
		).finalize(e.pos);
	}
	public function addChild(e:Expr, ?t:Type):Expr {
		return doAddChild.bind(target, e).bounce();
	}
	public function addString(s:String, pos:Position):Expr {
		var s = s.toExpr(pos);
		return (macro $target.addChild(Xml.createPCData($s))).finalize(pos);
	}
	public function buildNode(nodeName:Expr, props:Array<Expr>, children:Array<Expr>, pos:Position, yield:Expr->Expr):Expr {
		var ret = [open().define((macro Xml.createElement($nodeName)).finalize(pos), pos)];
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
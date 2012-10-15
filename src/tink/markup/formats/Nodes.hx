package tink.markup.formats;

import haxe.macro.Expr;
import haxe.macro.Format;

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
		return open().define(pos.at(macro Xml.createDocument()));
	}
	public function finalize(pos:Position):Null<Expr> {
		return close();
	}
	public function defaultTag(pos:Position):Expr {
		return 'div'.toExpr(pos);
	}
	public function postprocess(e:Expr):Expr {
		return e.pos.at(macro $e.firstChild());
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
		value = callback(stringifyProp, value).bounce();
		var attr = attr.toExpr(pos);
		return pos.at(macro $target.set($attr, $value));
	}
	function addChildNode(e:Expr):Expr {
		return e.pos.at(macro $target.addChild($e));
	}
	function doAddChild(target:Expr, e:Expr):Expr {
		return e.pos.at(
			if (e.is(XML))
				macro $target.addChild($e)
			else if (e.is(STRING)) 
				macro $target.addChild(Xml.createPCData($e))
			else
				macro $target.addChild(Std.string(Xml.createPCData($e)))
		);
	}
	public function addChild(e:Expr, ?t:Type):Expr {
		return callback(doAddChild, target, e).bounce();
	}
	public function addString(s:String, pos:Position):Expr {
		var s = s.toExpr(pos);
		return pos.at(macro $target.addChild(Xml.createPCData($s)));
	}
	public function buildNode(nodeName:Expr, props:Array<Expr>, children:Array<Expr>, pos:Position, yield:Expr->Expr):Expr {
		var ret = [open().define(pos.at(macro Xml.createElement($nodeName)))];
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
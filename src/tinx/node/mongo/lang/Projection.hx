package tinx.node.mongo.lang;

import haxe.ds.StringMap;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import tinx.node.mongo.lang.Path;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
using Lambda;

private typedef Node = StringMap<{ pos: Position, op:Op }>;

private enum Op {
	Plain;
	Slice(skip:Null<ExprOf<Int>>, limit:ExprOf<Int>, further:Null<Node>);
	Restrict(children:Node);
}

private class KV<V> {
	public var key(default, null):String;
	public var value(default, null):V;
	public function new(key, value) {
		this.key = key;
		this.value = value;
	}
}

private class Typer {
	static function flatten(n:Node, prefix:Array<StringAt>, out:Array<{ path:Path, op:Op }>) 
		if (n != null)
			for (name in n.keys()) {
				var f = n.get(name);
				var full = prefix.concat([new StringAt(name, f.pos)]);
				function yield()
					out.push( { path: new Path(full), op: f.op } );
				switch (f.op) {
					case Plain: yield();
					case Slice(_, _, _): yield();
					case Restrict(n): flatten(n, full, out);
				}
			}	
}
private class Parser {	
	static public function parse(exprs:Array<Expr>) {
		var ret = new Node();
		for (e in exprs) {
			var f = parseOp(e);
			if (ret.exists(f.key))
				e.reject('duplicate rules for ' + f.key);
			ret.set(f.key, { pos: e.pos, op: f.value });
		}
		return ret;
	}
	static public function parseSlice(skip:Expr, limit:Expr, next) {
		for (e in [skip, limit])
			if (e != null) 
				e.typeof().sure();
				
		var kv = parseOp(next);
		var further = 
			switch (kv.value) {
				case Plain: null;
				case Restrict(c): c;
				case Slice(_, _, _): next.reject();
			}
		return new KV(kv.key, Slice(skip, limit, further));
	}
	static public function parseOp(e:Expr):KV<Op> {
		return
			switch (e.expr) {
				case EConst(CIdent(s)): 
					new KV(s, Plain);	
				case ECall( { expr: EConst(CIdent(s)) }, params):
					new KV(s, Restrict(parse(params)));
				case EMeta( { name: 'slice', params:[limit] }, next):
					parseSlice(null, limit, next);
				case EMeta( { name: 'slice', params:[skip, limit] }, next):	
					parseSlice(skip, limit, next);
				default: e.reject();	
			}
	}
}

class Projection {
	static public function parse(input:Array<Expr>):Node {
		return Parser.parse(input);
	}
	static function buildExpr(rep:Node, t:TypeInfo):Expr {
		var ret = [];
		for (name in rep.keys()) {
			function field(e)
				ret.push( { field: name, expr: e } );
			var prj = rep.get(name);
			var sub = t.get(name, prj.pos);
			var fExpr = sub.blank(prj.pos);
			switch (prj.op) {
				case Plain: 
					field(fExpr);
				case Slice(_, _, c): 
					if (!sub.isArray())
						prj.pos.error('slicing only allowed on arrays');
					if (c == null) 
						field(sub.blank(prj.pos))
					else
						field([buildExpr(c, sub.get('[]', prj.pos))].toArray());
				case Restrict(c):
					if (sub.isArray()) {
						field([buildExpr(c, sub.get('[]', prj.pos))].toArray());
					}
					else field(buildExpr(c, sub));
			}
		}
		return EObjectDecl(ret).at();
	}
	static function buildProto(rep:Node, t:TypeInfo):Expr {
		var ret = buildExpr(rep, t);
		ret.typeof().sure();
		return ret;
	}
	static public function typeCheck(rep:Node, info:TypeInfo):Expr 
		return
			if (rep.empty()) {
				var t = Context.toComplexType(info.t.reduce());
				if (t == null) info.blank();
				else switch (t) {
					case TAnonymous(fields):
						if (!info.has('_id'))
							fields.push( { 
								name : '_id', 
								kind: FVar(macro : tinx.node.mongo.ObjectID), 
								pos: info.pos
							});
						ECheckType(macro null, t).at();
					case TExtend(p, fields):
						p;
						fields;
						ECheckType(macro null, t).at();
					default: info.blank();
				}
			}
			else 
				buildProto(rep, info);
			
	static function doCompile(rep:Node, prefix:Array<String>, field:String->Expr->Void) {
		for (name in rep.keys()) {
			var full = prefix.concat([name]);
			switch (rep.get(name).op) {
				case Plain: field(full.join('.'), macro 1);
				case Slice(skip, limit, further): 
					if (further != null)
						doCompile(further, full, field);
					field(
						full.join('.'), 
						EObjectDecl([{ 
							field: '$$slice',
							expr: if (skip == null) limit else [skip, limit].toArray()
						}]).at()
					);
				case Restrict(children):
					if (children.empty())
						field(full.join('.'), macro 1);
					else
						doCompile(children, full, field);
			}
		}
	}
	static public function generate(rep:Node):Expr {
		var ret = [];
		doCompile(rep, [], function (field, expr) ret.push({ field: field, expr: expr }));
		return EObjectDecl(ret).at();
	}
}
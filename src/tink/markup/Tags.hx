package tink.markup;

#if macro
	import haxe.macro.Expr;
	import tink.macro.tools.AST;
	import tink.markup.MarkupBuilder;
	using tink.macro.tools.MacroTools;
	using StringTools;
	using tink.core.types.Outcome;
#end
/**
 * ...
 * @author back2dos
 */

class Tags {
	#if macro	
		function new() {
			
		}
		public function boot():Expr {
			return [].toBlock();
		}
		public function finalize(e:Expr, t:Expr->Expr):Expr {
			return e;
		}
		public function enter(e:Expr, t:Expr->Expr) {
			e = e.ifNull('div'.resolve(e.pos));
			return 
				if (e.typeof().isSuccess()) e;
				else
					switch (e.getIdent()) {
						case Success(name):
							AST.build(Xml.createElement('eval__name'), e.pos);
						default: drillPlus(e, t);
					}
		}
		public function exit():Expr {
			return [].toBlock();
		}
		public function add(parent:Expr, child:Expr, pos:Position):Expr {
			return AST.build(tink.markup.Tags.__add($parent, $child), pos);
		}
		public function init(target:Expr, annotations:Annotations, attributes:Array<{field:String, expr:Expr}>, pos:Position):Expr {
			var cls = [],
				id = null;
			for (a in annotations.values)
				if (a.startsWith('$')) 
					id = a.substr(1);
				else 
					cls.push(a);
			
			var ret = [];
			
			if (id != null) 
				ret.push(set(target, 'id', id.toExpr(pos), pos));
			if (cls.length > 0)
				ret.push(set(target, 'class', cls.join(' ').toExpr(pos), pos));
			
			var toString = 'Std.string'.resolve(pos);
			for (a in attributes)
				ret.push(set(target, a.field, toString.call([a.expr], pos), a.expr.pos));
			
			return ret.toBlock(pos);
		}
		function set(target:Expr, prop:String, value:Expr, pos:Position):Expr {
			if (prop.startsWith('@$__hx__')) 
				prop = prop.substr(8);
			return AST.build($target.set('eval__prop', $value), pos);
		}
		function drillPlus(e:Expr, t:Expr->Expr):Expr {
			return 
				switch (OpAdd.get(e)) {
					case Success(op):
						t(drillPlus(op.e1, t)).add(t(drillPlus(op.e2, t)), op.pos);
					default: e;
				}
		}
		public function fix(wrong:Expr, reason:Dynamic, transformer:Expr->Expr):Expr {
			return drillPlus(wrong, transformer);
		}
		static function interpolateString(e:Expr) {
			return
				if (e.getString().isSuccess()) haxe.macro.Format.format(e);
				else e;
		}
		static function doAdd(p:Expr, c:Expr, to:Array<Expr>):Array<Expr> {
			return 
				switch (OpAdd.get(c)) {
					case Success(op):
						doAdd(p, op.e1, to);
						doAdd(p, op.e2, to);
						to;
					default:
						switch (c.typeof()) {
							case Success(t):
								if (t.getID() != 'Xml')
									c = AST.build(Xml.createPCData(Std.string($c)));
							default:
						}
						to.push(AST.build($p.addChild($c)));
						to;
				}
		}
	#end
	@:macro static public function build(e:Expr):Expr {
		return ECheckType(MarkupBuilder.build(new Tags(), e.transform(interpolateString)), 'Xml'.asTypePath()).at(e.pos);
	}
	@:macro static public function __add(p:Expr, c:Expr) {//TODO: I think this is overcomplicating things
		c = c.unbounce();
		return doAdd(p, c, []).toBlock();
	}
}
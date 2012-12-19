package tink.lang;
#if macro
	import haxe.macro.Context;
	import haxe.macro.Expr;
	import tink.lang.macros.Forward;
	
	using tink.macro.tools.MacroTools;
	using tink.core.types.Outcome;
#end
class Sugar {
	@:macro static public function select(target:ExprOf<{}>, ?filter:Expr) {
		
		var name = String.tempName();
		
		var ret = [name.define(target, target.pos)],
			src = name.resolve(target.pos),
			fields = [],
			filter = 
			if (filter.getIdent().equals('null')) 
				function (_) return true;
			else 
				Forward.makeFieldFilter(filter);
			
		for (f in target.typeof().sure().getFields(false).sure()) 
			if (f.isPublic && f.isVar() && filter(f))
				fields.push({
					field: f.name,
					expr: src.field(f.name, target.pos)
				});
		
		ret.push(EObjectDecl(fields).at(target.pos));
		return ret.toBlock();
	}
	@:macro static public function merge(rest:Array<Expr>) {
		//var target = rest.shift();
		//if (target == null)
			//Context.currentPos().error('no source given');
		var ret = [],
			fields = [],
			used = new Hash();
		rest.reverse();
		for (o in rest) {
			var name = String.tempName();
			ret.push(name.define(o, o.pos));
			var src = name.resolve(o.pos);
			
			for (f in o.typeof().sure().getFields().sure())
				if (f.isPublic && !used.exists(f.name))
					switch (f.kind) {
						case FVar(_, _):
							used.set(f.name, true);
							fields.push({
								field: f.name,
								expr: src.field(f.name, f.pos)
							});							
						default:
					}
		}
		ret.push(EObjectDecl(fields).at());
		return ret.toBlock();		
	}
}
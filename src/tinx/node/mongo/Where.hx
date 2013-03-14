package tinx.node.mongo;

import tinx.node.mongo.Internal;

#if macro
	import haxe.macro.Expr;
	import tinx.node.mongo.lang.Update;
	import tinx.node.mongo.lang.Projection;
	
	using tink.macro.tools.MacroTools;
	using tinx.node.mongo.lang.TypeInfo;
	using tinx.node.mongo.lang.Compiler;
#end
class Where<T> extends CollectionBase<T> {
	#if !macro
		var match:Dynamic;
		public function new(c:Collection<T>, match) {
			super(c.native);
			this.match = match;
		}
		public function remove() {
			
		}
		public function removeAll() {
			
		}
	#else
		static function find(ethis:Expr, func:String, projection:Array<Expr>) {
			ethis = macro @:privateAccess $ethis;
			var info = ethis.getInfo();
			var projection = Projection.compile(projection, info);
			var proto = projection.type;
			return (macro {
				var tmp = $ethis;
				@:privateAccess tmp.find($proto, tmp.match, ${projection.expr});
			}).finalize({ find: '_' + func });
		}		
		static function update(ethis:Expr, updates:Array<Expr>, options:Expr) {
			ethis = macro @:privateAccess $ethis;
			var info = ethis.getInfo();
			var projection = Update.compile(updates, info);
			return (macro {
				var tmp = $ethis;
				@:privateAccess tmp._update(tmp.match, ${projection.expr}, $options);
			});
		}
	#end
	
	macro public function first(ethis:Expr, projection:Array<Expr>) 
		return find(ethis, 'findOne', projection);
	
	macro public function slice(ethis:Expr, skip:ExprOf<Int>, limit:ExprOf<Int>	, projection:Array<Expr>) 
		return macro${find(ethis, 'find', projection)}.toArray();
		
	macro public function all(ethis:Expr, projection:Array<Expr>) 
		return macro${find(ethis, 'find', projection)}.toArray();
	
	macro public function cursor(ethis:Expr, projection:Array<Expr>) 
		return find(ethis, 'find', projection);
	
	macro public function updateFirst(ethis:Expr, updates:Array<Expr>) 
		return update(ethis, updates, macro { } );
	
	macro public function updateAll(ethis:Expr, updates:Array<Expr>) 
		return update(ethis, updates, macro { multi : true } );
	
}
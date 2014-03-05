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
		public function new(c:Collection<T>, match:Dynamic) {
			super(c.native);
			this.match = match;
		}
		public function remove() 
			return _remove(match, true);
		public function removeAll() 
			return _remove(match, false);
	#else
		static function escape(f:String)
			return 
				if (f.charAt(0) == '$')
					"@$__hx__"+f;
				else f;
		static function restore(ethis:Expr) {
			ethis = ethis.transform(function (e) return switch e.expr {
				case EObjectDecl(fields):
					EObjectDecl([for (f in fields) { field: escape(f.field), expr: f.expr }]).at(e.pos);
				default: e;
			});
			ethis = macro @:privateAccess $ethis;
			return ethis;			
		}
		static function find(ethis:Expr, func:String, projection:Array<Expr>) {
			ethis = restore(ethis);
			// throw ethis.toString();
			var info = ethis.getInfo();
			var projection = Projection.compile(projection, info);
			var proto = projection.type;
			func = '_$func';
			return macro {
				var tmp = $ethis;
				@:privateAccess tmp.$func($proto, tmp.match, ${projection.expr});
			}
		}		
		
		static function update(ethis:Expr, updates:Array<Expr>, options:Expr) {
			ethis = restore(ethis);
			var info = ethis.getInfo();
			var update = Update.compile(updates, info);
			return (macro {
				var tmp = $ethis;
				@:privateAccess tmp._update(tmp.match, ${update.expr}, $options);
			});
		}		
		static function findAndModify(ethis:Expr, updates:Array<Expr>, options:Expr) {
			ethis = restore(ethis);
			var info = ethis.getInfo();
			var update = Update.compile(updates, info),
				proto = Projection.compile([], info).type;
			return (macro {
				var tmp = $ethis;
				@:privateAccess tmp._findAndModify($proto, tmp.match, ${update.expr}, $options);
			});
		}
	#end
	
	macro public function first(ethis:Expr, projection:Array<Expr>) 
		return find(ethis, 'findOne', projection);
	
	macro public function slice(ethis:Expr, skip:ExprOf<Int>, limit:ExprOf<Int>	, projection:Array<Expr>) 
		return macro @:privateAccess $ethis.cursor($a{projection}).skip($skip).limit($limit).toArray();// $ { find(ethis, 'find', projection) } .toArray();
		
	macro public function all(ethis:Expr, projection:Array<Expr>) 
		return macro${find(ethis, 'find', projection)}.toArray();
	
	macro public function cursor(ethis:Expr, projection:Array<Expr>) 
		return find(ethis, 'find', projection);
	
	macro public function updateFirst(ethis:Expr, updates:Array<Expr>) 
		return update(ethis, updates, macro { } );
	
	macro public function updateAll(ethis:Expr, updates:Array<Expr>) 
		return update(ethis, updates, macro { multi : true } );
		
	macro public function getAndUpdate(ethis:Expr, updates:Array<Expr>) 
		return findAndModify(ethis, updates, macro { "new" : false } );
		
	macro public function updateAndGet(ethis:Expr, updates:Array<Expr>) 
		return findAndModify(ethis, updates, macro { "new" : true } );
	
}
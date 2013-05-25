package tink.reflect;

import haxe.rtti.Meta;
import tink.devtools.Benchmark;

#if macro
	import haxe.macro.Context;
	import haxe.macro.Type;
	import haxe.macro.Expr;
#else
	class Property {
		static inline function call(owner:Dynamic, name:String, args:Array<Dynamic>):Dynamic {
			return Reflect.callMethod(owner, Reflect.field(owner, name), args);
		}
		static public inline function get<O, T>(owner:O, name:String):T {
			var access:Access = Reflect.field(getInfo(Type.getClass(owner)), name);
			return
				if (access != null && access.read != null) 
					#if (js || flash)
						untyped owner[access.read]();
					#elseif neko
						untyped $objcall(owner, $hash(access.read.__s), $array());
					#else
						call(owner, access.read, []);
					#end
				else 
					Reflect.field(owner, name);
		}
		
		static public inline function set<O, T>(owner:O, name:String, value:T):T {
			var access:Access = Reflect.field(getInfo(Type.getClass(owner)), name);
			return
				if (access != null && access.write != null) 
					#if (js || flash)
						untyped owner[access.write](value);
					#elseif neko
						untyped $objcall(owner, $hash(access.write.__s), $array(value));
					#else
						call(owner, access.write, [value]);
					#end
				else {
					Reflect.setField(owner, name, value);
					value;
				}
		}
		
		static var cache = 
			#if flash9
				new flash.utils.TypedDictionary();
			#elseif (neko || js || flash)
				null;
			#else
				new Map();
			#end
		static inline function getForClass(cl:Class<Dynamic>) {
			return 
				#if flash9
					cache.get(cl);
				#elseif (neko || js || flash)
					untyped cl.__propCache__;
				#else
					cache.get(Type.getClassName(cl));
				#end
		}
		static inline function cacheForClass(cl:Class<Dynamic>, info:Dynamic<Access>) {
			#if flash9
				cache.set(cl, info);
			#elseif (neko || js || flash9)
				untyped cl.__propCache__ = info;
			#else
				cache.set(Type.getClassName(cl), info);
			#end
		}
		static function getInfo(cl:Class<Dynamic>):Dynamic<Access> {
			if (cl == null) return { };
			
			var ret = getForClass(cl);
			if (ret == null) {
				ret = Reflect.copy(getInfo(Type.getSuperClass(cl)));
				var own = Meta.getFields(cl);
				for (field in Reflect.fields(own)) 
					Reflect.setField(ret, field, new Access(Reflect.field(own, field)));
				cacheForClass(cl, ret);
			}
			return ret;
		}
		static function __init__() Store.properties({});
	}

	private class Access {
		public var read(default, null):Null<String>;
		public var write(default, null):Null<String>;
		public function new(source:Dynamic<Array<Dynamic>>) {
			if (source.__r != null) this.read = source.__r[0];
			if (source.__w != null) this.write = source.__w[0];
		}
	}
#end
private class Store {
	#if macro
		static function accessor(v:VarAccess, f:String, meta:MetaAccess, write:Bool, pos) 
			switch(v) {
				case AccCall:
					var name = write ? '__w' : '__r';
					if (!meta.has(name))
						meta.add(name, [Context.makeExpr(write ? 'set_$f' : 'get_$f', pos)], pos);
				default:
			}
		
		static function extract(types:Array<Type>) {
			for (type in types) {
				switch (Context.follow(type)) {
					case TInst(cl, _):
						var cl = cl.get();
						if (!cl.isInterface)
							for (field in cl.fields.get())
								switch (field.kind) {
									case FVar(read, write):
										accessor(read, field.name, field.meta, false, field.pos);
										accessor(write, field.name, field.meta, true, field.pos);
									default:
								}
					default:
				}
			}		
		}
	#end
	macro static public function properties(e) {
		Context.onGenerate(extract);
		return e;
	}	
}
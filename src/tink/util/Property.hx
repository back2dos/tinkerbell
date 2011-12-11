package tink.util;
import haxe.rtti.Meta;

/**
 * ...
 * @author back2dos
 */

class Property {
	static inline function call(owner:Dynamic, name:String, args:Array<Dynamic>) {
		return Reflect.callMethod(owner, Reflect.field(owner, name), args);
	}
	static public inline function get<O, T>(owner:O, name:String):T {
		var access:Access = Reflect.field(getInfo(Type.getClass(owner)), name);
		return
			if (access != null && access.read != null) 
				#if (js || flash)
					untyped owner[access.read]();
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
				#else
					call(owner, access.write, [value]);
				#end
			else {
				Reflect.setField(owner, name, value);
				value;
			}
	}
	
	static var cache = new Hash();
	static inline function getForClass(cl:Class<Dynamic>) {
		return 
			#if (neko || js)
				untyped cl.__p;
			#else
				cache.get(Type.getClassName(cl));
			#end
	}
	static inline function cacheForClass(cl:Class<Dynamic>, info:Dynamic<Access>) {
		#if (neko || js)
			untyped cl.__p = info;
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
	static function __init__() Store.properties()
}
private class Access {
	public var read(default, null):Null<String>;
	public var write(default, null):Null<String>;
	public function new(source:Dynamic<Array<Dynamic>>) {
		if (source.__r != null) this.read = source.__r[0];
		if (source.__w != null) this.write = source.__w[0];
	}
}

#if macro
	import haxe.macro.Context;
	import haxe.macro.Type;
	import tink.macro.tools.AST;
	import haxe.macro.Expr;
	using tink.macro.tools.MacroTools;
#end
private class Store {
	#if macro
		static function accessor(v:VarAccess, meta:MetaAccess, write:Bool, pos) {
			return switch(v) {
				case AccCall(m):
					meta.add(write ? '__w' : '__r', [m.toExpr()], pos);
				default:
			}
		}
		static function extract(types:Array<Type>) {
			for (type in types) {
				switch (type.reduce()) {
					case TInst(cl, _):
						for (field in cl.get().fields.get())
							switch (field.kind) {
								case FVar(read, write):
									accessor(read, field.meta, false, field.pos);
									accessor(write, field.meta, true, field.pos);
								default:
							}
					default:
				}
			}		
		}
	#end
	@:macro static public function properties() {
		Context.onGenerate(extract);
		return AST.build(new Hash<Dynamic<Access>>());
	}	
}
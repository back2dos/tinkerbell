package tink.collections.maps;

import tink.lang.Cls;

private class StringRepMap<T> extends tink.collections.maps.base.StringIDMap < Dynamic, T > {
	override function transform(k:Dynamic) {
		return Std.string(k); 
	}
}
#if js
	private class Ints<T> extends tink.collections.maps.base.IntIDMap < Int, T > {
		override function transform(k:Int) {
			return k;
		}
	}
#else
	private typedef Ints<T> = IntHash<T>
#end
class AnyMap<V> implements Map < Dynamic, V > , implements Cls {
	//TODO: consider using BoolMap as well
	var ints:Ints<V>;
	var strings:Hash<V>;
	var objs:ObjectMap<Dynamic, V>;
	var misc:StringRepMap<V>;
	var funcs:FunctionMap<Dynamic, V>;
	public function new() {
		this.ints = new Ints();
		this.strings = new Hash();
		this.objs = new ObjectMap();
		this.misc = new StringRepMap();
		this.funcs = new FunctionMap();
	}
	public function get(k:Dynamic):Null<V> {
		return
			switch (Type.typeof(k)) {
				case TNull, TBool, TFloat, TUnknown: misc.get(k);
				case TInt: ints.get(k);
				case TClass(c):
					if (c == String) strings.get(k);
					else objs.get(k);
				case TObject, TEnum(_): objs.get(k);
				case TFunction: funcs.get(k);
			}
	}
	public function set(k:Dynamic, v:V):V {
		switch (Type.typeof(k)) {
			case TNull, TBool, TFloat, TUnknown: misc.set(k, v);
			case TInt: ints.set(k, v);
			case TClass(c):
				if (c == String) strings.set(k, v);
				else objs.set(k, v);
			case TObject, TEnum(_): objs.set(k, v);
			case TFunction: funcs.set(k, v);
		}		
		return v;
	}
	public function exists(k:Dynamic):Bool {
		return
			switch (Type.typeof(k)) {
				case TNull, TBool, TFloat, TUnknown: misc.exists(k);
				case TInt: ints.exists(k);
				case TClass(c):
					if (c == String) strings.exists(k);
					else objs.exists(k);
				case TObject, TEnum(_): objs.exists(k);
				case TFunction: funcs.exists(k);
			}
	}
	public function remove(k:Dynamic):Bool {
		return
			switch (Type.typeof(k)) {
				case TNull, TBool, TFloat, TUnknown: misc.remove(k);
				case TInt: ints.remove(k);
				case TClass(c):
					if (c == String) strings.remove(k);
					else objs.remove(k);
				case TObject, TEnum(_): objs.remove(k);
				case TFunction: funcs.remove(k);
			}
	}
	//TODO: the untyped statement is uggly but I'm not sure there's an equally concise alternative
	public function keys():Iterator<Dynamic> {
		var a = new Array<Dynamic>();
		return group(untyped [untyped ints.keys(), strings.keys(), objs.keys(), misc.keys(), funcs.keys()]);
	}
	public function iterator():Iterator<V> {
		return group(untyped [ints.iterator(), strings.iterator(), objs.iterator(), misc.iterator(), funcs.iterator()]);		
	}
	function group<A>(a:Iterable<Iterator<A>>):Iterator<A> {//TODO: it might make sense extracting this
		var i = Lambda.filter(a, function (iter) return iter.hasNext()).iterator();
		return 
			if (i.hasNext()) {
				var cur = i.next();
				{
					hasNext: function () return cur.hasNext() || i.hasNext(),
					next: function () {
						if (!cur.hasNext()) cur = i.next();
						return cur.next();
					}
				}
			}
			else [].iterator();//TODO: unlazify
	}
}
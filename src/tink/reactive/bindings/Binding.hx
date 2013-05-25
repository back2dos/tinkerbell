package tink.reactive.bindings;

import haxe.Timer;
import tink.collections.maps.*;
import tink.lang.Cls;
import tink.reactive.Source;

class Watch<T> extends Binding<T> implements Source<T> {
	public var value(get_value, null):T;
	#if (cpp || php) //works around haXe issue #699
		override function get_value() return super.get_value();
	#end
	public function new(get) {
		super(get);
	}
}
class Control<T> extends Binding<T> implements Editable<T> {
	public var value(get_value, set_value):T;
	#if (cpp || php) //works around haXe issue #699
		override function get_value() return super.get_value();
	#end
	var set:T->T;
	public function new(get, set) {
		this.set = set;
		super(get);
	}
	function set_value(v:T) {
		var ret = set(v);
		invalidate();
		return ret;
	}
}
class Link<T> {
	var site:Control<T>;
	var watch:Source<T>;
	var control:Editable<T>;
	var changing:Bool;
	function new() {
		changing = false;
	}
	
	function siteChanged() {
		if (!changing && control != null) {
			control.value = site.value;
		}
	}
	function watchChanged() {
		if (!changing) {
			changing = true;
			site.value = watch.value;
			changing = false;
		}
	}
	public function init(get, set) {
		if (site == null) {
			site = new Control(get, set);
			site.watch(siteChanged);
		}
	}
	public function single(s:Source<T>) {
		if (watch != null)
			watch.unwatch(watchChanged);
		control = null;
		watch = s;
		if (s != null) {
			s.watch(watchChanged);
			site.value = s.value;
		}
	}
	public function twoway(c:Editable<T>) {
		single(c);
		control = c;
	}
	public function drop() {	
		if (site != null) {
			site.unwatch(siteChanged);
			site = null;
		}
		if (watch != null) {
			watch.unwatch(watchChanged);
			watch = null;
		}
		control = null;
	}
	static var targetMap = new ObjectMap();
	static public function by<A>(target:Dynamic, key:Dynamic):Link<A> {
		var keyMap = targetMap.get(target);
		if (keyMap == null)
			targetMap.set(target, keyMap = new AnyMap());
		var ret = keyMap.get(key);
		if (ret == null)
			ret = keyMap.set(key, new Link<A>());
		return ret;
	}
	
}
private typedef Cb = Void->Void;
class Binding<T> implements Cls {
	public var valid(default, null):Bool;
	static var stack = new List<Binding<Dynamic>>();
	static var idCounter = 0;
	public var id(default, null):Int = idCounter++;
	var calc:Void->T;
	var cache:T;
	var busy:Bool;
	var handlers = new FunctionMap<Cb, Cb>();
	function new(calc) {
		this.calc = calc;
	}
	public function unwatch(handler:Cb):Void {
		handlers.remove(handler);
	}
	public function watch(handler:Cb):Void {
		handlers.set(handler, handler);
	}	
	public function invalidate() {
		if (valid) {//invalidated bindings don't need to fire really
			valid = false;
			untyped this.bindings.byString.fire('value', null);//TODO: this doesn't work because of cyclic dependency
			for (h in handlers) h();
		}
	}
	public var revision = 0;
	function doCalc() {
		if (busy) 
			throw 'cyclic binding occured';
		stack.push(this);
		stack.length;
		busy = true;
		revision += 1;
		cache = calc();
		busy = false;
		valid = true;
		stack.pop();
		return cache;
	}
	@:bindable("value") private function get_value():T {
		return
			if (valid) cache;
			else 
				doCalc();
	}
	static public inline function current() {
		return stack.first();
	}
}


private typedef BindingMap = Map<Int,Binding<Dynamic>>;

#if !js
@:generic 
#end
private class SingleSignaller<T, M:Map.IMap<T, BindingMap>> {
	var keyMap:M;
	var revisions:IntMap<Int>;
	public function new(keyMap) {
		this.keyMap = keyMap;
		this.revisions = new IntMap();
	}
	public inline function bind<A>(key:T, ?ret:A) {
		watch(key, Binding.current());
		return ret;
	}
	function watch(key:T, watcher:Binding<Dynamic>) {
		if (watcher == null) return;
		var bindings = keyMap.get(key);
		if (bindings == null)
			keyMap.set(key, bindings = new Map());
		bindings.set(watcher.id, watcher);
		revisions.set(watcher.id, watcher.revision);
	}
	public function fire<A>(key:T, ?ret:A) {
		if (keyMap.exists(key)) {
			var bindings = keyMap.get(key); 
			keyMap.set(key, new Map());
			for (b in bindings) {
				if (b.revision == revisions.get(b.id))
					b.invalidate();
			}
		}
		return ret;
	}
}
private class UnknownSignaller {
	//I had to do this, because Dynamic doesn't work with Generic
	var keyMap:AnyMap<BindingMap>;
	public function new() {
		this.keyMap = new AnyMap();
	}
	public inline function bind<A>(key:Dynamic, ?ret:A) {
		watch(key, Binding.current());
		return ret;
	}
	function watch(key:Dynamic, watcher:Binding<Dynamic>) {
		if (watcher == null) return;
		var bindings = keyMap.get(key);
		if (bindings == null)
			keyMap.set(key, bindings = new Map());
		bindings.set(watcher.id, watcher);
	}
	public function fire<A>(key:Dynamic, ?ret:A) {
		if (keyMap.exists(key)) {
			var bindings = keyMap.get(key); 
			keyMap.set(key, new Map());
			for (b in bindings) b.invalidate();
		}
		return ret;
	}
}
class Signaller implements Cls {
	public var byString = new SingleSignaller<String, StringMap<BindingMap>>(new StringMap());
	public var byInt = new SingleSignaller<Int, IntMap<BindingMap>>(new IntMap());
	public var byBool = new SingleSignaller<Bool, BoolMap<BindingMap>>(new BoolMap());
	public var byUnknown = new UnknownSignaller();
	public function new() {}
} 
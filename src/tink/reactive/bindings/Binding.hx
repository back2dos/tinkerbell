package tink.reactive.bindings;

import haxe.Timer;
import tink.collections.maps.AnyMap;
import tink.collections.maps.FunctionMap;
import tink.collections.maps.ObjectMap;
import tink.lang.Cls;
import tink.reactive.Source;

/**
 * ...
 * @author back2dos
 */

 
class Watch<T> extends Binding<T>, implements Source<T> {
	public var value(get_value, null):T;
	#if (cpp || php) //works around haXe issue #699
		override function get_value() return super.get_value()
	#end
	public function new(get) {
		super(get);
	}
}
class Control<T> extends Binding<T>, implements Editable<T> {
	public var value(get_value, set_value):T;
	#if (cpp || php) //works around haXe issue #699
		override function get_value() return super.get_value()
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
			keyMap = targetMap.set(target, new AnyMap());
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
			this.bindings.fire('value');
			for (h in handlers) h();
		}
	}
	function doCalc() {
		if (busy) 
			throw 'cyclic binding occured';
		stack.push(this);
		busy = true;
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

class Signaller {
	var keyMap:AnyMap<IntHash<Void->Void>>;
	public function new() {
		this.keyMap = new AnyMap();
	}
	public function bind<A>(key:Dynamic, ?ret:A) {
		watch(key, Binding.current());
		return ret;
	}
	function watch(key:Dynamic, watcher:Binding<Dynamic>) {
		if (watcher == null) return;
		var handlers = keyMap.get(key);
		if (handlers  == null)
			keyMap.set(key, handlers = new IntHash());
		handlers.set(watcher.id, watcher.invalidate);
	}
	public function fire<A>(key:Dynamic, ?ret:A) {
		if (keyMap.exists(key)) {
			var handlers = keyMap.get(key); 
			keyMap.set(key, new IntHash());
			for (h in handlers) h();
		}
		return ret;
	}
} 

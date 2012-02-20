package tink.tween;

import haxe.FastList;
import haxe.Timer;
import tink.collections.ObjectMap;
import tink.lang.Cls;
/**
 * ...
 * @author back2dos
 */
private typedef Component = Float->Dynamic;
private typedef Atom<T> = T->Component;
private typedef Tweens = FastList<Tween<Dynamic>>;

class Tween<T> {
	public var target(default, null):T;
	public var progress(default, null):Float;
	public var duration(default, null):Float;
	public var group(default, null):TweenGroup;
	var onDone:Void->Dynamic;
	var easing:Float->Float;
	var components:Array<Component>;
	var properties:Array<String>;
	
	
	function update(delta:Float):Bool {
		progress += delta / duration;
		var done = progress >= 1;
		if (done) 
			progress = 1;
		var amplitude = easing(progress);
		for (c in components) 
			c(amplitude);
		return done;
	}
	function cleanup():Void {
		targetMap.get(target).remove(this);
		for (c in components) 
			c(Math.POSITIVE_INFINITY);
			
		onDone();
		this.target = null;
		this.easing = null;
		this.components = null;
		this.properties = null;
	}
	public function freeProperties(free:String->Bool):Void {
		var ps = [], cs = [], i = 0;
		for (p in properties) {
			if (free(p)) 
				components[i](Math.POSITIVE_INFINITY);
			else {
				ps.push(p);
				cs.push(components[i]);
			}
			i++;
		}
		this.properties = ps;
		this.components = cs;		
	}
	static var after = [];
	static var before = [];
	static var active = new Tweens();
	static var last = Math.NaN;
	static public inline function beforeHeartbeat(f:Void->Void) { before.push(f); }
	static public inline function afterHeartbeat(f:Void->Void) { after.push(f); }
	static public function heartbeat(delta:Float) {
		var oldBefore = before;
		before = [];
		for (f in oldBefore) f();
		
		if (Math.isNaN(delta)) {
			if (Math.isNaN(last)) 
				last = Timer.stamp();
			delta = Timer.stamp() - last;
		}
		delta *= speed;
		var old = active,
			done = new Tweens(),
			alive = new Tweens();
		active = alive;
		for (t in old)
			if (t.update(delta))
				done.add(t);
			else
				alive.add(t);
		for (t in done)
			t.cleanup();
		last = Timer.stamp();
		var oldAfter = after;
		after = [];
		for (f in oldAfter) f();
	}
	static var targetMap = new ObjectMap<Dynamic, Array<Tween<Dynamic>>>();
	static public function byTarget<A>(target:A):Iterable<A> {//returning Iterable here because we don't want people to screw around with this
		var ret = targetMap.get(target);
		if (ret == null)
			ret = targetMap.set(target, []);
		return cast ret;
	}
	static function register(tween:Tween<Dynamic>, kill:String->Bool) {
		if (targetMap.exists(tween.target)) 
			for (t in targetMap.get(tween.target))
				t.freeProperties(kill);
		else
			targetMap.set(tween.target, []);
		
		targetMap.get(tween.target).push(tween);
	}
	static public var defaultEasing = Math.sqrt;	
	static public var speed = 1.0;
	static var isHooked = false;
	#if (flash9 || nme)
		static public function useEnterFrame() {
			if (isHooked) return;
			isHooked = true;
			flash.Lib.current.addEventListener(flash.events.Event.ENTER_FRAME, function (_) {
				heartbeat(Math.NaN);
			});
			heartbeat(Math.NaN);
		}
	#elseif flash
		static public function useEnterFrame() {
			if (isHooked) return;
			isHooked = true;
			var r = flash.Lib.current;
			r.createEmptyMovieClip('tink_tween_beacon', r.getNextHighestDepth());
			r.onEnterFrame = callback(heartbeat, Math.NaN);
			r.onEnterFrame();
		}		
	#elseif js
		static public function setFPS(fps:Float) {
			if (isHooked) return;
			isHooked = true;
			var t = new haxe.Timer(Math.round(1000 / fps));
			t.run = callback(heartbeat, Math.NaN);
			t.run();
		}
	#end
}

class TweenParams<T> implements Cls {
	var propMap = new Hash<Bool>();
	var properties = new Array<String>();
	var atoms = new Array<Atom<T>>();
	
	public var group:TweenGroup;
	public var onDone:Tween<T>->Dynamic;
	public var duration = 1.0;
	public var easing = Tween.defaultEasing;
	
	public function new() {
		//this.group = group;
	}
	static function ignore():Void { }
	
	public function start(target:T):Tween<T> {
		var ret = RealTween.get();
		ret.init(target, properties, atoms, propMap.exists, duration, easing, onDone == null ? ignore : callback(onDone, ret));
		return ret;
	}
	public function addAtom(name:String, atom:Atom<T>) {
		if (!this.propMap.exists(name)) {
			this.propMap.set(name, true);
			this.properties.push(name);
			this.atoms.push(atom);
		}
	}
}

private class RealTween<T> extends Tween<T> {
	function new() {}
	static public function get<A>() {
		return new RealTween<A>();
	}
	public function init(target:T, properties:Array<String>, atoms:Array<Atom<T>>, exists, duration, easing, onDone) {
		this.onDone = onDone;
		this.target = target;
		this.properties = properties;
		this.components = [];
		this.duration = duration;
		this.easing = easing;
		
		Tween.register(this, exists);
		
		this.progress = 0;
		for (a in atoms)
			this.components.push(a(target));
		Tween.active.add(this);
	}
}
package tink.tween;

import haxe.FastList;
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
		targetMap.get(target).remove(this);//yes, that's O(N) where N is the number of concurrent tweens on one object, so N <= 5 is a reasonable assumption
		onDone();
		this.target = null;
		this.easing = null;
		this.components = null;
		this.properties = null;
	}
	public function freeProperties(toFreeOrNotToFree:String->Bool):Void {
		var ps = [], cs = [], i = 0;
		for (p in properties) {
			if (!toFreeOrNotToFree(p)) {
				ps.push(p);
				cs.push(components[i]);
			}
			i++;
		}
		this.properties = ps;
		this.components = cs;		
	}
	static var active = new Tweens();
	static public function hearbeat(delta:Float) {
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
class TweenParams<T> implements Cls {
	var propMap = new Hash<Bool>();
	var properties = new Array<String>();
	var atoms = new Array<Atom<T>>();
	public var onDone:Tween<T>->Dynamic;
	public var duration = 1.0;
	public var easing = Math.sqrt;
	
	public function new() { }
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
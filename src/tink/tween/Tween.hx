package tink.tween;

import haxe.FastList;
import haxe.Timer;
import tink.collections.maps.ObjectMap;
import tink.lang.Cls;
import tink.tween.plugins.Plugin;

typedef TweenCallback = Void->Void;
typedef TweenComponent = Float->Null<TweenCallback>;
typedef TweenAtom<T> = T->TweenComponent;
private typedef Tweens = FastList<Tween<Dynamic>>;

class Tween<T> {
	public var target(default, null):T;
	public var progress(default, null):Float;
	public var duration(default, null):Float;
	public var group(default, null):TweenGroup;
	
	public var paused:Bool;
	
	var cue:Cue<T>;
	var cueIndex:Int;
	var onDone:Void->Void;
	var onStarve:Void->Void;
	var easing:Float->Float;
	var components:Array<TweenComponent>;
	var properties:Array<String>;
	
	#if !php inline #end //inlining will generate incorrect code in PHP
	function clamp(f:Float) {
		return
			if (f < .0) 0.0;
			else if (f > 1.0) 1.0;
			else f;
	}
	function update(delta:Float):Float {
		return 
			if (properties.length == 0) .0;
			else if (paused) Math.POSITIVE_INFINITY;
			else {
				progress += delta / duration;
				var amplitude = easing(clamp(progress));
				for (c in components) 
					group.afterHeartbeat(c(amplitude));
				if (cueIndex > -1) {
					if (delta >= 0) {
						while (cueIndex < cue.length) 
							if (cue[cueIndex].mark <= progress) {
								cue[cueIndex].handler(this, true);
								cueIndex++;
							}
							else break;
					}
					else throw 'not implemented';
				}
				(1 - progress) * delta;				
			}
	}
	function cleanup():Void {
		targetMap.get(target).remove(this);
		for (c in components) 
			c(Math.POSITIVE_INFINITY);
		if (properties.length > 0)	
			onDone();
		else
			onStarve();
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
	static public var defaultEasing = function (f:Float) return Math.sin(0.5 * f * Math.PI);
}
private class CuePoint<T> {
	public var mark(default, null):Float;
	public var handler(default, null):Tween<T>->Bool->Void;
	public function new(mark, handler) {
		this.mark = mark;
		this.handler = handler;
	}
}
private typedef Cue<T> = Array<CuePoint<T>>;
class TweenParams<T> implements Cls {
	var propMap = new Hash<Bool>();
	var properties = new Array<String>();
	var atoms = new Array<TweenAtom<T>>();
	var cue = new Cue<T>();
	public var onDone:Tween<T>->Void;
	public var onStarve:Tween<T>->Void;
	public var duration = 1.0;
	public var easing = Tween.defaultEasing;
	public var overwrite = false;
	public function new() {}
	static function ignore() { }
	static function overwriteAll(_) return true
	public function start(group, target:T):Tween<T> {
		var ret = RealTween.get();
		ret.init(
			group, 
			target, 
			cue, 
			properties, 
			atoms, 
			overwrite ? overwriteAll : propMap.exists, 
			duration, 
			easing, 
			onDone == null ? ignore : onDone.bind(ret),
			onStarve == null ? ignore : onStarve.bind(ret)
		);
		return ret;
	}
	public function addCuePoint(mark, handler:Tween<T>->Bool->Void) {
		if (cue.length == 0 || cue[cue.length-1].mark <= mark)
			this.cue.push(new CuePoint(mark, handler));	
		else {
			for (i in 0...cue.length+1)
				if (cue[i].mark > mark) {
					cue.insert(i, new CuePoint(mark, handler));
					break;
				}
			5;
		}
	}
	public function addAtom(name:String, atom:TweenAtom<T>):Void {
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
	public function init(group:TweenGroup, target:T, cue:Cue<T>, properties:Array<String>, atoms:Array<TweenAtom<T>>, exists, duration, easing, onDone, onStarve) {
		this.onDone = onDone;
		this.onStarve = onStarve;
		this.group = group;
		this.cue = cue;
		this.cueIndex = cue.length > 0 ? 0 : -1;
		this.target = target;
		this.properties = properties;
		this.components = [];
		this.duration = duration;
		this.easing = easing;
		
		Tween.register(this, exists);
		
		this.progress = 0;
		for (a in atoms)
			this.components.push(a(target));
		group.addTween(this);
	}
}
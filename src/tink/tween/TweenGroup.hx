package tink.tween;

import haxe.ds.GenericStack in FastList;
import haxe.Timer;
import tink.devtools.Debug;
import tink.lang.Cls;

private typedef Tweens = FastList<Tween<Dynamic>>; 
private typedef Handlers = Array<Void->Void>;

class TweenGroup implements Cls {
	public var speed = 1.0;
	
	var active:Tweens = new Tweens();
	var before = new Handlers();
	var after = new Handlers();
	var last = Math.NaN;
	var unhook:Void->Void;
	
	public function new() {}
	public function addTween<A>(tween:Tween<A>):Tween<A> {
		Debug.assert(tween != null, tween.group == this);
		this.active.add(cast tween);
		return tween;
	}
	public inline function beforeHeartbeat(f:Void->Void) { if (f != null) before.push(f); }
	public inline function afterHeartbeat(f:Void->Void) { if (f != null) after.push(f); }
	public function hookTo(hook:(Float->Float)->(Void->Void)) {
		if (unhook != null)
			unhook();
		unhook = hook(heartbeat);
	}
	function handleBefore() {
		var oldBefore = before;
		before = new Handlers();
		for (f in oldBefore) f();		
	}
	function handleAfter() {
		var oldAfter = after;
		after = new Handlers();
		for (f in oldAfter) f();
	}
	function calcIfNeeded(delta:Float) {
		return
			if (Math.isNaN(delta)) {
				if (Math.isNaN(last)) 
					last = Timer.stamp();
				Timer.stamp() - last;
			}
			else delta;
	}
	public function heartbeat(delta:Float) {
		handleBefore();
		
		delta = calcIfNeeded(delta) * speed;
		
		last = Timer.stamp();
		
		var old = active,
			done = new Tweens(),
			alive = new Tweens(),
			left = 0.0,
			leftMin = Math.POSITIVE_INFINITY;
			
		active = alive;
		
		for (t in old) {
			left = update(t, delta);
			if (left > 0) {
				alive.add(t);
				if (left < leftMin) 
					leftMin = left;				
			}
			else done.add(t);
		}
						
		for (t in done)
			cleanup(t);
			
		handleAfter();
		
		return leftMin;
	}
	inline function update(t:TweenInternal, delta:Float) {
		return t.update(delta);
	}
	inline function cleanup(t:TweenInternal) {
		t.cleanup();
	}
}
private typedef TweenInternal = {
	private function update(delta:Float):Float;
	private function cleanup():Void;
}
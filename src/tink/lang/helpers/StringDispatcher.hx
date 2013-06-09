package tink.lang.helpers;
import tink.core.types.Callback;

private typedef Minimal = {
	function add(event:String, handler:Dynamic):Void;
	function remove(event:String, handler:Dynamic):Void;
}
private typedef Capturing = {>Minimal,
	function addCapturing(event:String, handler:Dynamic):Void;
	function removeCapturing(event:String, handler:Dynamic):Void;
}
abstract StringDispatcher<T:Minimal>(T) {
	inline function new(of:T) this = of;
	public function watch<A>(event:String, c:Callback<A>):CallbackLink {
		var f = function (e) c.invoke(e);
		this.add(event, f);
		return this.remove.bind(event, f);
	}
	inline function self():T return this;
	static public function capture<A>(dispatcher:StringDispatcher<Capturing>, event:String, c:Callback<A>):CallbackLink {
		var f = function (e) c.invoke(e);
		dispatcher.self().addCapturing(event, f);
		return dispatcher.self().removeCapturing.bind(event, f);		
	}
	static public function promote<A:Minimal>(s:StringDispatcher<A>):StringDispatcher<A> return s;
	#if js
		static inline function attach(e:Dynamic, event:String, handler:Dynamic) 
			e.attachEvent('on$event', handler);
		static inline function detach(e:Dynamic, event:String, handler:Dynamic) 
			e.detachEvent('on$event', handler);
		
		@:from static function ofEventTarget(e:js.html.EventTarget) {
			var std = Reflect.field(e, 'addEventListener');
			return new StringDispatcher({ //TODO: consider dealing with IE7- right here
				add: function (event, handler:Dynamic) 
					if (std)
						e.addEventListener(event, handler)
					else 
						attach(e, event, handler),
				remove: function (event, handler:Dynamic) 
					if (std)
						e.removeEventListener(event, handler)
					else
						detach(e, event, handler),
				addCapturing: function (event, handler:Dynamic) 
					if (std)
						e.addEventListener(event, handler, true)
					else 
						attach(e, event, handler),
				removeCapturing: function (event, handler:Dynamic) 
					if (std)
						e.removeEventListener(event, handler, true)
					else
						detach(e, event, handler),
			});
		}
	#end
	#if (flash || nme) 
		@:from static inline function ofEventDispatcher(e:flash.events.IEventDispatcher)
			return new StringDispatcher({
				add: function (event, handler:Dynamic) e.addEventListener(event, handler),
				remove: function (event, handler:Dynamic) e.removeEventListener(event, handler),
				addCapturing: function (event, handler:Dynamic) e.addEventListener(event, handler, true),
				removeCapturing: function (event, handler:Dynamic) e.removeEventListener(event, handler, true),
			});
		
	#end
}
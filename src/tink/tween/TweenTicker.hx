package tink.tween;

class TweenTicker {
	static public function free(group:TweenGroup) {
		group.hookTo(function (_) return function () { } );
	}
	static function nothing() {}
	static public function toNext(group:TweenGroup) {
		var inner = nothing;
		var ret = function () {
			inner();
		}
		group.hookTo(function (update) {
			var next = update(0);
			inner = function () {
				next = update(next);
			}
			return function () {
				inner = nothing;
			}
		});
		return ret;
	}
	#if (flash9 || nme)
		static public function framewise(group:TweenGroup) {
			group.hookTo(function (update) {
				update(0);
				var f = function (_) update(Math.NaN);
				flash.Lib.current.addEventListener(flash.events.Event.ENTER_FRAME, f);
				return function () 
					flash.Lib.current.removeEventListener(flash.events.Event.ENTER_FRAME, f);
			});
		}
	#elseif flash
		static public function framewise(group:TweenGroup) {
			var root = flash.Lib.current;
			var depth = root.getNextHighestDepth();
			var beacon = root.createEmptyMovieClip('tink_tween_beacon_' + depth, depth);
			
			group.hookTo(function (update) {
				beacon.onEnterFrame = cast update.bind(Math.NaN);
				update(0);
				return function () {
					beacon.onEnterFrame = null;
					beacon.removeMovieClip();
				}
			});
		}
	#elseif js
		static public function framewise(group:TweenGroup) {
			if (Reflect.field(js.Browser.window, 'requestAnimationFrame')) {
				//TODO: cannot actually perceive an improvement. Also, frames should only be requested when tweens are available
				group.hookTo(function (update) {
					update(0);
					var id = 0;
					function next(_) {
						id = js.Browser.window.requestAnimationFrame(next);
						update(Math.NaN);
						return true;
					}
					next(0);
					return function () js.Browser.window.cancelAnimationFrame(id);
				});
			}
			else periodic(group, 16);
		}
	#end
	static public function periodic(group:TweenGroup, ?time_ms:Int = 20) {
		var t = new haxe.Timer(time_ms);
		group.hookTo(function (update) {
			t.run = function () update(Math.NaN);
			update(0);
			return t.stop;
		});
	}
}
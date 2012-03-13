package tink.reactive;

/**
 * ...
 * @author back2dos
 */

		interface Source<T> {
			var value(get_value, null):T;
			function unwatch(handler:Void->Void):Void;
			function watch(handler:Void->Void):Void;
		}
		interface Editable<T> implements Source<T> {
			var value(get_value, set_value):T;
		}
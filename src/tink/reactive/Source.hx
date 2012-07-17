package tink.reactive;
import tink.collections.maps.FunctionMap;
import tink.lang.Cls;

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
class PlainSource<T> implements Source<T>, implements Editable<T>, implements Cls {
	var handlers = new FunctionMap<Void->Void, Void->Void>();	
	public function unwatch(handler:Void->Void):Void {
		handlers.remove(handler);
	}
	public function watch(handler:Void->Void):Void {
		handlers.set(handler, handler);
	}		
	
	public var value(get_value, set_value):T = _;
	function get_value() return value
	function set_value(param) {
		value = param;
		for (h in handlers) h();
		return param;
	}
	
}
/*
TODO: consider using this instead, after some profiling 
typedef Source<T> = {
	var value(get_value, null):T;
	function unwatch(handler:Void->Void):Void;
	function watch(handler:Void->Void):Void;
}
typedef Editable<T> = {
	var value(get_value, set_value):T;
	function unwatch(handler:Void->Void):Void;
	function watch(handler:Void->Void):Void;
}*/
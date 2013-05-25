package tink.reactive.bindings;

import tink.lang.Cls;

class BindableArray<T> implements Cls {
	var data:Array<T>;
	static inline var CHANGE = 'change';//TODO: all this is not particularly granular, but optimizing it is non-trivial since operations like shift mess with the whole array
	@:bindable(change) @:read(data.length) var length:Int;
	public function new(?data) {
		this.data = data | if (null) [];
	}
	function onChange<T>(value:T) {
		this.bindings.byString.fire(CHANGE);
		this.bindings.byString.fire('length');//TODO: temporary fix, because overwriting keys doesn't work just yet for fields/properties
		return value;
	}
	@:bindable(CHANGE) public function first() 
		return data[0];
	@:bindable(CHANGE) public function last() 
		return data[data.length - 1];
		
	public function move(from:Int, to:Int) {
		data.insert(to, data.splice(from, 1)[0]);
		onChange(null);
	}
	public function push(x:T):Int {
		return onChange(data.push(x));
	}
	public function pop(x:T):Null<T> {
		return onChange(data.pop());
	}
	public function unshift(x:T):Int {
		onChange(data.unshift(x));
		return length;
	}
	public function remove(x:T):Bool 
		return data.remove(x) && onChange(true);
	
	public function shift():Null<T> 
		return onChange(data.shift());
	
	public function insert(pos, x) 
		onChange(data.insert(pos, x));
    
    public function toString() {
        return '@:bindable '+data.toString();
    }
    
	@:bindable(CHANGE) public function indexOf(item:T):Int {
		for (i in 0...data.length) 
			if (data[i] == item) return i;
		return -1;
	}
	public function splice(?pos = 0, ?len = -1, ?nu:Array<T>) {
        if (len == -1) len = data.length - pos;
		data.splice(pos, len);
		onChange(data = data.slice(0, pos).concat(nu).concat(data.slice(pos)));
	}
	@:bindable(CHANGE) public function slice(pos, ?end) 
		return data.slice(pos, end | if (null) data.length);
	
	@:bindable(CHANGE) public function get(index:Int) 
		return data[index];
	
	public function set(index:Int, x:T) 
		return onChange(data[index] = x);
	
	@:bindable(CHANGE) public function iterator():Iterator<T>
		return data.iterator();
	
	@:bindable(CHANGE) public function toArray()
		return data.copy();
}
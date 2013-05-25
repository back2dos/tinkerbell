package tinx.node.mongo.lang;

//TODO: this might just as well go into tink_macros

using StringTools;

import haxe.ds.StringMap;
import haxe.macro.Expr;

using tink.core.types.Outcome;
using tink.macro.tools.MacroTools;

class Path {
	var parts:Array<StringAt>;
	
	public var length(get, null):Int;
	public var last(get, null):StringAt;
	public var first(get, null):StringAt;
	
	public function new(parts) {
		this.parts = parts;
	}
	
	inline function get_length() return parts.length;
	inline function get_last() return get(length - 1);
	inline function get_first() return get(0);
	public function getPos(?fallback) 
		return
			if (length == 0) fallback
			else last.pos;
	
	public inline function join(sep)
		return parts.join(sep);
		
	public inline function slice(start, ?end)
		return new Path(parts.slice(start, end));
		
	public inline function iterator()
		return parts.iterator();
		
	public inline function get(index) 
		return parts[index];
	
	static function parse(e:Expr):Array<StringAt> 
		return
			switch (e.expr) {
				case EField(owner, field):
					parse(owner).concat([new StringAt(field, e.pos)]);
				default: 
					[StringAt.of(e)];
			}		
			
	static public function of(e:Expr) 
		return new Path(parse(e));
	
}

class StringAt {
	public var s(default, null):String;
	public var pos(default, null):Position;
	public function new(s, pos) {
		this.s = s;
		this.pos = pos;
	}
	public function getFrom<A>(h:StringMap<A>, ?key:String = 'field')
		return 
			if (h.exists(s)) h.get(s);
			else pos.error('unknown $key $s');
			
	public inline function toString() 
		return s;
		
	public inline function startsWith(tk)
		return s.startsWith(tk);
		
	static inline public function of(e:Expr) 
		return 
			new StringAt(e.getName().sure(), e.pos);
				
}

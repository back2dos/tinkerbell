package tink.macro.build;

typedef Enums = Type;

import haxe.macro.Context;
import haxe.macro.Type;
using tink.macro.tools.ExprTools;
/**
 * ...
 * @author back2dos
 */

@:macro class Builder {
	static public function buildFields():Array<haxe.macro.Expr.Field> {
		return new Helper().build();
	}
}
private typedef Plugin = Array<Member>->Constructor->(String->Bool)->(Member->Member)->Void;

private class Helper {
	
	var members:Hash<Member>;
	var constructor:Constructor;
	var localClass:ClassType;
	public function new() { 
		members = new Hash();
		localClass = Context.getLocalClass().get();
	}

	public function build() {
		var declared = [];
		for (field in Context.getBuildFields()) 
			addMember(declared, Member.ofHaxe(field));
			
		if (constructor == null) 
			if (localClass.superClass != null && localClass.superClass.t.get().constructor != null) 
				null.error('please specify a constructor with a call to the super constructor');
			else
				constructor = new Constructor(null);
		
		var generated = [];
		for (plugin in PLUGINS)
			plugin(declared, constructor, hasMember, callback(addMember, generated));	
			
		var ret = [constructor.toHaxe()];
		for (member in declared.concat(generated))
			ret.push(member.toHaxe());
		return ret;
	}
		
	function hasMember(name:String) {
		return 
			if (name == 'new')
				constructor != null;
			else
				members.exists(name);
	}
	function addMember(to:Array<Member>, m:Member) {
		if (hasMember(m.name)) 
			m.pos.error('duplicate member declaration ' + m.name);
			
		if (m.name == 'new') 
			this.constructor = new Constructor(Enums.enumParameters(m.kind)[0], m.isPublic);
		else {
			members.set(m.name, m);
			to.push(m);				
		}
		return m;
	}	
	static var PLUGINS:Array<Plugin> = [
		Init.process,
		Forward.process,
		Property.process,
	];
	
}
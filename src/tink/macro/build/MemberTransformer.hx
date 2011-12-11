package tink.macro.build;

typedef Enums = Type;

import haxe.macro.Context;
import haxe.macro.Type;

using tink.macro.tools.MacroTools;

/**
 * ...
 * @author back2dos
 */

typedef ClassBuildContext = {
	cls:ClassType,
	members:Array<Member>,
	ctor:Constructor,
	has:String->Bool,
	add:Member->Member
}
class MemberTransformer {
	
	var members:Hash<Member>;
	var constructor:Constructor;
	var localClass:ClassType;
	public function new() { 
		members = new Hash();
		localClass = Context.getLocalClass().get();
	}

	public function build(plugins:Iterable<ClassBuildContext->Void>) {
		var declared = [];
		for (field in Context.getBuildFields()) 
			addMember(declared, Member.ofHaxe(field));
			
		if (constructor == null) 
			if (localClass.superClass != null && localClass.superClass.t.get().constructor != null) 
				localClass.pos.error('please specify a constructor with a call to the super constructor');
			else
				constructor = new Constructor(null);
		
		var generated = [];
		var context = {
			cls: localClass,
			members: declared,
			ctor: constructor,
			has: hasMember,
			add: callback(addMember, generated)
		}
		for (plugin in plugins)
			plugin(context);	
			
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
}
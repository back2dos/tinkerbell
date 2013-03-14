package tink.macro.build;

import haxe.macro.Printer;
import Type in Enums;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
using Lambda;

typedef ClassBuildContext = {
	cls:ClassType,
	members:Array<Member>,
	getCtor:Void->Constructor,
	hasCtor:Void->Bool,
	has:String->Bool,
	get:String->Member,
	hasOwn:String->Bool,
	add:Member->?Bool->Member
}
class MemberTransformer {
	
	var members:Hash<Member>;
	var macros:Hash<Field>;
	var constructor:Null<Constructor>;
	var localClass:ClassType;
	var superFields:Hash<Bool>;
	var verbose:Bool;
	public function new(?verbose) { 
		members = new Hash();
		macros = new Hash();
		localClass = Context.getLocalClass().get();
		//trace(localClass);
		this.verbose = verbose;
		switch (localClass.kind) {
			case KAbstractImpl(a):
				var meta = localClass.meta;
				for (tag in a.get().meta.get())
					if (!meta.has(tag.name)) {
						//tag.pos.warning('copied');
						meta.add(tag.name, tag.params, tag.pos);
					}
				this.verbose = meta.has(':verbose');//TODO: remove this workaround
			default:
		}
	}
	function getConstructor() {
		if (constructor == null) 
			if (localClass.superClass != null && localClass.superClass.t.get().constructor != null) {
				try {
					var ctor = Context.getLocalClass().get().superClass.t.get().constructor.get();
					var func = Context.getTypedExpr(ctor.expr()).getFunction().sure();

					//TODO: Remove this workaround for haxe bug #1505. 
					for (arg in func.args)
						arg.type = null;
						
					func.expr = "super".resolve().call(func.getArgIdents());
					constructor = new Constructor(localClass.isInterface, func);
					if (ctor.isPublic)
						constructor.publish();					
				}
				catch (e:Dynamic) {//fails for unknown reason
					if (e == 'assert')
						neko.Lib.rethrow(e);
					constructor = new Constructor(localClass.isInterface, null);
				}
			}
			else
				constructor = new Constructor(localClass.isInterface, null);
		return constructor;
	}
	function prune(a:Array<Member>) {
		var ret = [];
		for (m in a) 
			if (!m.excluded) 
				ret.push(m);
		return ret;
	}
	public function build(plugins:Iterable<ClassBuildContext->Void>) {
		var fields = [];
		for (field in Context.getBuildFields()) 
			if (field.access.has(AMacro))
				macros.set(field.name, field)
			else
				addMember(fields, Member.ofHaxe(field));
			
		var context = {
			cls: localClass,
			members: fields,
			getCtor: getConstructor,
			hasCtor: function () return constructor != null,
			has: hasMember,
			get: getOwnMember,
			hasOwn: hasOwnMember,
			add: null
		}
		
		for (plugin in plugins) {
			context.add = addMember.bind(context.members, _, _);
			
			plugin(context);	
			
			context.members = prune(context.members);
		}
		
		var ret = (constructor == null || localClass.isInterface) ? [] : [constructor.toHaxe()];
		for (member in context.members) {
			if (member.isBound)
				switch (member.kind) {//TODO: this seems like an awful place for a cleanup. If all else fails, this should go into a separate plugin (?)
					case FVar(_, _): if (!member.isStatic) member.isBound = null;
					case FProp(_, _, _, _): member.isBound = null;
					default:
				}
			ret.push(member.toHaxe());
		}
		for (m in macros)
			ret.push(m);
		if (verbose) 
			for (field in ret) 
				Context.warning(new Printer().printField(field), field.pos);
		return ret;
	}
	function getOwnMember(name:String) {
		return 
			if (hasOwnMember(name)) 
				members.get(name);
			else
				null;
	}
	
	function hasOwnMember(name:String) {
		return 
			if (name == 'new')
				constructor != null;
			else
				macros.exists(name) || (members.exists(name) && !members.get(name).excluded);
	}
	function hasSuperField(name:String) {
		if (superFields == null) {
			superFields = new Hash();
			var cl = localClass.superClass;
			while (cl != null) {
				var c = cl.t.get();
				for (f in c.fields.get())
					superFields.set(f.name, true);
				cl = c.superClass;
			}
		}
		return superFields.get(name);
	}
	function hasMember(name:String) {
		return hasOwnMember(name) || hasSuperField(name);
	}
	function addMember(to:Array<Member>, m:Member, ?front = false) {
		if (hasOwnMember(m.name)) 
			m.pos.error('duplicate member declaration ' + m.name);
			
		if (m.name == 'new') 
			this.constructor = new Constructor(localClass.isInterface, Enums.enumParameters(m.kind)[0], m.isPublic, m.pos);
		else {
			members.set(m.name, m);
			if (front) to.unshift(m);
			else to.push(m);				
		}
		return m;
	}		
}
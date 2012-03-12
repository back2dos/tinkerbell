package tink.lang.macros;

/**
 * ...
 * @author back2dos
 */
import haxe.macro.Expr;
import tink.macro.build.Constructor;
import tink.macro.build.Member;
import tink.macro.tools.AST;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

class PropBuilder {
	
	static public inline var BINDABLE = ':bindable';
	static public inline var FULL = ':prop';
	static public inline var READ = ':read';
	
	static public function process(ctx) {
		new PropBuilder(ctx.has, ctx.add, ctx.getCtor()).processMembers(ctx.members);
	}
	static public function make(m:Member, t:ComplexType, getter:Expr, setter:Null<Expr>, hasField:String->Bool, addField:Member->Member) {
		var get = 'get_' + m.name,
			set = if (setter == null) 'null' else 'set_' + m.name;
			
		if (!hasField(get))	
			addField(Member.getter(m.name, getter, t)); 	
		if (setter != null && !hasField(set))
			addField(Member.setter(m.name, setter, t));
		
		m.kind = FProp(get, set, t, null);
		m.isPublic = true;
		return m;
	}
	var hasField:String->Bool;
	var addField:Member->Member;
	var ctor:Constructor;
	function new(hasField, addField, ctor) {
		this.hasField = hasField;
		this.addField = addField;
		this.ctor = ctor;
	}
	function makeBindable(pos:Position) {
		if (!hasField('bindings')) {
			var t = 'tink.reactive.bindings.Binding'.asTypePath('Signaller');
			if (!t.toType().isSuccess())
				pos.error('please make sure to use -lib tink_reactive if you want to use bindable properties');
			//TODO: find a nicer mechanism to inject this here
			ctor.init('bindings', pos, AST.build(new tink.reactive.bindings.Binding.Signaller(), pos), true);
			addField(Member.plain('bindings', t, pos));
		}		
	}
	function processMembers(members:Array<Member>) {
		for (member in members)
			switch (member.kind) {
				case FVar(t, e):
					if (member.isStatic) continue;//skipped for now					
					if (member.isPublic == false) continue;//explicitly private variables are not elligible for accessor generation
					
					#if display
						if (member.extractMeta(READ).isSuccess() || member.extractMeta(FULL).isSuccess())
							member.isPublic = true;
						if (member.extractMeta(BINDABLE).isSuccess()) {
							member.isPublic = true;
							makeBindable(member.pos);
						}
					#else
						var meta = member.meta,
							name = member.name;
						
						switch (member.extractMeta(READ)) {
							case Success(tag):
								member.disallowMeta(FULL, READ);	
								var get = 
									switch (tag.params.length) {
										case 0, 1: 
											[tag.params[0], '_'.resolve(tag.pos)];
										default: 
											tag.pos.error('too many arguments');
									}
								member.addMeta(FULL, tag.pos, get);
							default:
						}
						switch (member.extractMeta(FULL)) {
							case Success(tag):
								var getter = null,
									setter = null,
									field = ['this', name].drill(tag.pos);
								switch (tag.params.length) {
									case 0:
										getter = field;
										setter = field.assign('param'.resolve());
									case 1: 
										getter = field;
										setter = field.assign(tag.params[0], tag.params[0].pos);
									case 2: 
										getter = tag.params[0];
										if (getter == null)
											getter = field;
											
										setter = tag.params[1];
										if (setter.isWildcard()) setter = null;
									default:
										tag.pos.error('too many arguments');
								}
								if (member.extractMeta(BINDABLE).isSuccess()) {
									makeBindable(tag.pos);
									getter = [AST.build(bindings.bind("eval__name"), tag.pos), getter].toBlock(tag.pos);
									if (setter != null)
										setter = [AST.build(bindings.fire("eval__name"), tag.pos), setter].toBlock(tag.pos);
								}
								make(member, t, getter, setter, hasField, addField);
							default:	
								switch (member.extractMeta(BINDABLE)) {
									case Success(tag):
										makeBindable(tag.pos);
										var getter = AST.build( {
											bindings.bind("eval__name");
											this.eval__name;
										}, tag.pos);
										var setter = AST.build( {
											bindings.fire("eval__name");
											this.eval__name = param;
										});
										make(member, t, getter, setter, hasField, addField);
									default:
								}
								
						}												
					#end
					case FFun(f):
						switch (member.extractMeta(BINDABLE)) {
							case Success(tag):
								var name = 
									switch (tag.params.length) {
										case 0: member.name;
										case 1: tag.params[0].getName().sure();
										default: tag.pos.error('too many arguments');
									}
								makeBindable(tag.pos);
								f.expr = [AST.build(bindings.bind("eval__name"), tag.pos), f.expr].toBlock(tag.pos);
							default:
						}
				default: //maybe do something here?
			}		
	}
}
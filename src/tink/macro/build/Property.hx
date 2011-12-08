package tink.macro.build;

/**
 * ...
 * @author back2dos
 */
import haxe.macro.Expr;
using tink.macro.tools.ExprTools;
using tink.util.Outcome;
class Property {
	static public inline var FULL = ':prop';
	static public inline var READ = ':read';
	static public function process(members:Array<Member>, constructor:Constructor, hasField:String->Bool, addField:Member->Member) {
		new Property(hasField, addField).processMembers(members);
	}
	static public function make(m:Member, t:ComplexType, getter:Expr, setter:Null<Expr>, hasField:String->Bool, addField:Member->Member) {
		var get = 'get_' + m.name,
			set = if (setter == null) 'null' else 'set_' + m.name;
			
		if (!hasField(get))	
			addField(Member.method(get, getter.func(t))); 	
		if (setter != null && !hasField(set))
			addField(Member.method(set, setter.func([ { name:'param', opt:false, type:t, value:null } ], t)));			
		
		m.kind = FProp(get, set, t, null);
		m.isPublic = true;
		return m;
	}
	var hasField:String->Bool;
	var addField:Member->Member;
	function new(hasField, addField) {
		this.hasField = hasField;
		this.addField = addField;
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
										setter =
											if (setter.isWildcard()) null;
											else 
												[
													field.assign(setter), 
													field
												].toBlock(tag.pos);
									default:
										tag.pos.error('too many arguments');
								}
								make(member, t, getter, setter, hasField, addField);
							default:	
						}						
						
						//member.kind = FProp(get, set, t, null);
					#end
				default: //maybe do something here?
			}		
	}
}
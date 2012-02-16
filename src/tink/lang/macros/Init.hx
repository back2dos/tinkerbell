package tink.lang.macros;

import haxe.macro.Expr;
import tink.macro.build.Constructor;
import tink.macro.build.Member;
/**
 * ...
 * @author back2dos
 */
using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

class Init {
	static public function process(ctx) {
		new Init(ctx.getCtor()).init(ctx.members);
	}
	var constructor:Constructor;
	function new(constructor) {
		this.constructor = constructor;
	}
	function getType(t:Null<ComplexType>, inferFrom:Expr) {
		return
			if (t == null) 
				inferFrom.typeof().data().toComplex();
			else 
				t;
	}
	function init(members:Array<Member>) {
		for (member in members) {
			if (!member.isStatic)
				switch (member.kind) {
					case FVar(t, e):
						if (e != null) {
							member.kind = FVar(getType(t, e));
							initMember(member, e);
						}
					case FProp(get, set, t, e):
						if (e != null) {
							member.kind = FProp(get, set, getType(t, e));
							initMember(member, e);
						}						
					default:
				}
		}
	}
	function initMember(member:Member, e:Expr) {
		var init = null,
			def = null;
		if (!e.isWildcard())
			switch (e.expr) {
				case EParenthesis(e): def = e;
				default: init = e;
			}
		this.constructor.init(member.name, e.pos, init, def);		
	}
}
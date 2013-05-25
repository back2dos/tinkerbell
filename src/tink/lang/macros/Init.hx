package tink.lang.macros;

import haxe.macro.Expr;
import tink.macro.build.Constructor;
import tink.macro.build.Member;
import tink.macro.build.MemberTransformer;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

class Init {
	static public function process(ctx) {
		new Init(ctx).init(ctx.members);
	}
	var ctx:ClassBuildContext;
	function new(ctx) {
		this.ctx = ctx;
	}
	function getType(t:Null<ComplexType>, inferFrom:Expr) {
		return
			if (t == null) 
				inferFrom.typeof().sure().toComplex(true);
			else 
				t;
	}
	function init(members:Array<Member>) {
		for (member in members) {
			if (!member.isStatic)
				switch (member.kind) {
					case FVar(t, e):
						if (e != null) {
							member.kind = FVar(t = getType(t, e), null);
							Init.member(ctx, member, t, e);
						}
					case FProp(get, set, t, e):
						if (e != null) {
							member.kind = FProp(get, set, t = getType(t, e), null);
							Init.member(ctx, member, t, e);
						}						
					default:
				}
		}
	}
	static public function member(ctx:ClassBuildContext, member:Member, t:ComplexType, e:Expr) {
		if (ctx.cls.isInterface) 
			member.addMeta(':default', e.pos, [ECheckType(e, t).at(e.pos)]);
		else 
			field(ctx.getCtor(), member.name, t, e);
	}
	static public function field(ctor:Constructor, name, t:ComplexType, e:Expr) {
		var init = null,
			def = null;
		if (!e.isWildcard())
			switch (e.expr) {
				case EParenthesis(e): def = e;
				default: init = e;
			}
		ctor.init(name, e.pos, init, def, t);							
	}
}
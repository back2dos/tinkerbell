package tink.lang.macros;

import tink.macro.build.Member;
import tink.macro.build.MemberTransformer;
import haxe.macro.Type;
import haxe.macro.Expr;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

class PartialImpl {
	static function getDefault(f:ClassField) {
		var tags = f.meta.get().getValues(':default');
		return
			switch (tags.length) {
				case 0: null;
				case 1: tags[0][0];
				case 2: f.pos.error('multiple defaults defined');
			}
	}
	static public function process(ctx:ClassBuildContext) {
		if (ctx.cls.isInterface) 
			for (m in ctx.members) 
				switch (m.kind) {
					case FFun(f):
						if (f.expr != null) {
							m.addMeta(':default', f.expr.pos, [EFunction(null, Reflect.copy(f)).at(f.expr.pos)]);
							f.expr = null;
						}
					default:
				}
		else {
			for (i in ctx.cls.interfaces)
				for (f in TInst(i.t, i.params).getFields(true).sure()) {
					if (!ctx.has(f.name)) {
						switch (f.kind) {
							case FVar(read, write):
								ctx.add(Member.ofHaxe( {
									name: f.name,
									access: f.isPublic ? [APublic] : [APrivate],
									kind: FProp(read.accessToName(), write.accessToName(), f.type.toComplex()),
									pos: f.pos
								}));
								var d = getDefault(f);
								if (d != null)
									switch (d.expr) {
										case ECheckType(e, t):
											Init.field(ctx.getCtor(), f.name, t, e);
										default:
											Init.field(ctx.getCtor(), f.name, f.type.toComplex(), d);//for people who specify this manually
									}
							case FMethod(_):
								var d = getDefault(f);
								if (d != null) {
									switch (d.expr) {
										case EFunction(_, impl):
											ctx.add(Member.ofHaxe( {
												name: f.name,
												access: f.isPublic ? [APublic] : [APrivate],
												kind: FFun(impl),
												pos: f.pos
											}));									
										default:
											d.reject();
									}
								}
								
						}
					}
				}
		}
	}
	
}
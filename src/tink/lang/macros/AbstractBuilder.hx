package tink.lang.macros;

import tink.macro.build.Member;
import tink.macro.build.MemberTransformer;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

class AbstractBuilder {
	static function process(ctx:ClassBuildContext) {
		var native = ctx.cls.meta.get().getValues(':native');
		
		ctx.cls.exclude();
		
		if (native.length != 1)
			ctx.cls.pos.error('requires exactly one @:native tag');
		
		var pos = native[0][0].pos,
			native = native[0][0].getString().sure().asComplexType();
			
		ctx.add(Member.method('toNative', pos, (macro untyped this).func(native)));
		ctx.add(
			Member.method(
				'of', 
				pos, 
				(macro untyped v).func(
					['v'.toArg(native)], 
					ctx.cls.name.asComplexType()
				)
			)
		).isStatic = true;
		
		for (m in ctx.members) {
			var f = m.getFunction().sure();
			m.isBound = true;
			m.addMeta(':extern', m.pos);
			m.publish();
		}
		
	}
	static public function build() 
		return new MemberTransformer().build([process]);
}
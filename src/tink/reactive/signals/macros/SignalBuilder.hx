package tink.reactive.signals.macros;

import tink.lang.macros.Init;
import tink.lang.macros.PropBuilder;
import tink.macro.build.Member;
import tink.macro.build.MemberTransformer;
import haxe.macro.Expr;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

class SignalBuilder {
	static inline var SIGNAL = ':signal';
	static public function make(ctx:ClassBuildContext) {
		for (member in ctx.members) 
			switch (member.extractMeta(SIGNAL)) {
				case Success(tag):
					switch (member.kind) {
						case FVar(t, e):
							if (t == null) 
								t = macro : Void;
							var name = 
								switch (tag.params.length) {
									case 0: member.name;
									case 1: tag.params[0].getIdent().sure();
									default: tag.pos.error('too many arguments');
								}
							var types = 
								switch (t) {
									case TPath({ name: 'Void' }):
										{ 
											cls : 'tink.reactive.signals.Signal.SimpleVoidSignal',
											own : macro : tink.reactive.signals.Signal.SimpleVoidSignal,
											published : macro : tink.reactive.signals.Signal.VoidSignal,
										}
									default:
										{ 
											cls : 'tink.reactive.signals.Signal.SimpleSignal',
											own : macro : tink.reactive.signals.Signal.SimpleSignal<$t>,
											published : 
												'tink.reactive.signals.Signal.Named'.asComplexType([
													TPExpr(name.toExpr()),
													TPType(macro : tink.reactive.signals.Signal<$t>)
												])
										}
								}
							if (e == null) {
								var own = '_' + member.name;
								
								member.kind = FVar(types.published);
								member.addMeta(PropBuilder.READ, tag.pos, [own.resolve(tag.pos)]);
								ctx.add(Member.plain(own, types.own, tag.pos, types.cls.instantiate(tag.pos))).isPublic = false;								
							}
							else {
								member.addMeta(PropBuilder.READ, tag.pos);
								member.kind = FVar(types.published, e);								
							}
						default: 
							member.pos.error('can only declare signals on variables');
					}
				default:
			}
	}
}
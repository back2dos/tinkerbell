package tink.reactive.signals.macros;

import tink.lang.macros.Init;
import tink.lang.macros.PropBuilder;
import tink.macro.build.Member;
import tink.macro.build.MemberTransformer;
import haxe.macro.Expr;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

class SignalBuilder {
	static var types = [
		':signal' => {
			published: function (t) return macro : tink.core.types.Signal<$t>,
			internal: function (pos, t) return macro @:pos(pos) new tink.core.types.Callback.CallbackList<$t>()
		},
		':future' => {
			published: function (t) return macro : tink.core.types.Future<$t>,
			internal: function (pos, t) return macro @:pos(pos) tink.core.types.Future.create()
		}
	];
	static public function make(ctx:ClassBuildContext) {
		for (type in types.keys()) {
			var make = types.get(type);
			for (member in ctx.members) 	
				switch (member.extractMeta(type)) {
					case Success(tag):
						switch (member.kind) {
							case FVar(t, e):
								if (t == null)
									t = if (e == null) macro : tink.core.types.Signal.Noise;
										else e.pos.makeBlankType();
								member.publish();
								if (e == null) {	
									var own = '_' + member.name;
									ctx.add(
										Member.plain(
											own, 
											null,
											tag.pos, 
											make.internal(tag.pos, t)
										), 
										true
									).isPublic = false;	
									e = 
										if (type == ':signal')
											macro @:pos(tag.pos) $i{own}.toSignal();
										else
											macro @:pos(tag.pos) $i{own}.asFuture();
									//TODO: it's probably better to expose the signal through a getter
								}
								member.kind = FProp('default', 'null', make.published(t), e);
							default:
								member.pos.error('can only declare signals on variables');
						}
					default:
				}
		}
	}
}
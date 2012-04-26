package tink.reactive.signals.macros;

/**
 * ...
 * @author back2dos
 */
import tink.macro.build.Member;
import tink.macro.build.MemberTransformer;
import haxe.macro.Expr;

using tink.macro.tools.MacroTools;

class SignalBuilder {
	static inline var SIGNAL = ':signal';
	static public function make(ctx:ClassBuildContext) {
		for (member in ctx.members) 
			switch (member.extractMeta(SIGNAL)) {
				case Success(tag):
					switch (member.kind) {
						case FVar(t, e):
							if (e != null) e.reject();
							if (t == null) member.pos.error('type required');
							
							var own = '_' + member.name;
							ctx.add(Member.plain(own, 'tink.reactive.signals.Signal.SimpleSignal'.asComplexType([TPType(t)]), tag.pos));
							
							member.kind = FProp('default', 'null', 'tink.reactive.signals.Signal'.asComplexType([TPType(t)]));
							ctx.getCtor().init(member.name, tag.pos, own.resolve(tag.pos), true);
							ctx.getCtor().init(own, tag.pos, 'tink.reactive.signals.Signal.SimpleSignal'.instantiate(tag.pos), true);
							member.publish();
						default: 
							member.pos.error('can only declare signals on variables');
					}
				default:
			}
	}
}
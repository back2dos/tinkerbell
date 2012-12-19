package tink.lang.macros.node;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

import haxe.macro.Expr;
import tink.macro.build.Member;

class NodeEvent {
	static public function process(targetName:String, t:ComplexType, ctx:{ members:Array<Member> }) {
		var handlerName = 'handler';
		for (member in ctx.members) 
			switch (member.extractMeta(':event')) {
				case Success(tag):
					var f = member.getFunction().sure();
					if (f.expr != null) 
						f.expr.reject();
					if (f.ret == null) 
						f.ret = 'Dynamic'.asComplexType();	
						
					var pos = tag.pos,
						name = 
							switch (tag.params.length) {
								case 0: member.name;
								case 1: tag.params[0].getName().sure();
								default: tag.pos.error('too many parameters');
							}
						
					var target = targetName.resolve(pos),
						handlerArgs = [];
						
					for (arg in f.args)
						handlerArgs.push(arg.type);
						
					var f = [
						EUntyped(target.field("on", pos).call([name.toExpr(), handlerName.resolve(pos)], pos)).at(pos),
						target
					].toBlock().func([targetName.toArg(t), handlerName.toArg(TFunction(handlerArgs, f.ret))]);
					f.ret = t;
					
					member.kind = FFun(f);
					member.isBound = member.isStatic = true;
					member.publish();
				default:
			}
	}	
}
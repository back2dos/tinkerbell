package tink.macro.build;

/**
 * ...
 * @author back2dos
 */
using tink.macro.tools.MacroTools;
using tink.util.Outcome;
import haxe.macro.Expr;
class NodeEvent {
	static public function process(targetName:String, t:ComplexType, ctx:{ members:Array<Member> }) {
		var handlerName = 'handler';
		for (member in ctx.members) 
			switch (member.extractMeta(':event')) {
				case Success(tag):
					var f = member.getFunction().data();
					if (f.expr != null) 
						f.expr.reject();
					if (f.ret == null) 
						f.ret = 'Dynamic'.asTypePath();	
						
					var pos = tag.pos,
						name = 
							switch (tag.params.length) {
								case 0: member.name;
								case 1: tag.params[0].getName().data();
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
					member.isBound = member.isPublic = member.isStatic = true;
				default:
			}
	}	
}
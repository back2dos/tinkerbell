package tink.macro.build;

/**
 * ...
 * @author back2dos
 */
import haxe.macro.Expr;
import haxe.macro.Type;
using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

class Native {
	static public function process(targetName:String, t:ComplexType, ctx:{members:Array<Member>} ) {
		
		for (member in ctx.members) {
			switch (member.extractMeta(':native')) {
				case Success(tag):
					switch (member.kind) {
						case FFun(f):
							var native = 
								switch (tag.params.length) {
									case 0: {
										name: member.name,
										pos: member.pos
									}
									case 1: {
										name: tag.params[0].getName().data(),
										pos: tag.params[0].pos
									}
									default: tag.pos.error('too many arguments');
								}
							if (f.expr != null) 
								f.expr.reject();
							
							var args = [],
								pos = native.pos;
							for (arg in f.args) 
								args.push(arg.name.resolve(pos));
							
							var ret = EUntyped(targetName.resolve(pos)).at(pos).field(native.name, pos).call(args, pos);
							
							if (f.ret == null) {
								f.ret = t;
								ret = [ret, targetName.resolve(pos)].toBlock();
							}
							
							member.isBound = member.isPublic = member.isStatic = true;
							f.args.unshift(targetName.toArg(t));
							f.expr = EReturn(ret).at(pos);
						default:
							member.pos.error('cannot handle ' + member.kind);
					}
				default:
			}
		}
	}
}
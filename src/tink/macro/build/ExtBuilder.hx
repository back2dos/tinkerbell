package tink.macro.build;
import haxe.macro.Context;
using tink.macro.tools.MacroTools;
/**
 * ...
 * @author back2dos
 */

@:macro class ExtBuilder {
	static public function buildFields():Array<haxe.macro.Expr.Field> {
		var targetName = '_target';
		var cl = Context.getLocalClass().get();
		if (cl.superClass != null) 
			cl.pos.error('cannot subclass TinkExtern implementors');
		var t = null;
		for (i in cl.interfaces) 
			if (i.t.get().name == 'TinkExt') {
				t = i.params[0].toComplex();
				break;
			}
		if (t == null) 
			cl.pos.error('could not find type to be extended');
		
		
		return new MemberTransformer().build([
			callback(Native.process, targetName, t),
			callback(NodeEvent.process, targetName, t)
		]);
	}
	
}
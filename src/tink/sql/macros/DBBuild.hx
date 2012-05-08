package tink.sql.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import tink.macro.build.MemberTransformer;

using tink.macro.tools.MacroTools;
/**
 * ...
 * @author back2dos
 */

class DBBuild {
	@:macro static public function build():Array<Field> {
		return new MemberTransformer().build([bootTables]);
	}
	static function field(name:String, type:ComplexType, pos) {
		return {
			name: name, 
			doc: null,
			access: [],
			kind: FVar(type),
			pos: pos,
			meta: []
		};
	}
	
	static function bootTables(c:ClassBuildContext) {
		for (m in c.members) 
			switch (m.extractMeta(':table')) {
				case Success(tag):
					switch (m.kind) {
						case FVar(t, e):
							if (e != null) e.reject();
							
							var name = m.name;//TODO: allow table renaming
							
							t = 'tink.sql.Table'.asComplexType([
								TPType(Context.getLocalType().toComplex()),
								TPType(TAnonymous([field(name, t, m.pos)]))
							]);
							
							m.kind = FProp('default', 'null', t, null);
							m.publish();
							
							
							var t = {
								pack:'tink.sql'.split('.'),
								name:'Table',
								sub: null,
								params: []
							};
							
							//c.getCtor().init(m.name, m.pos, 'null'.resolve());
							c.getCtor().init(m.name, m.pos, ENew(t, ['this'.resolve(m.pos), name.toExpr(m.pos)]).at(m.pos));
						default:
							m.pos.error('can use variables only');
					}
				default:
			}
	}
}
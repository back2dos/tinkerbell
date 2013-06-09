package tink.lang.macros;

import haxe.macro.Expr;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

class ShortLambda {
	static public function postfix(e:Expr) 
		return
			switch e {
				case macro $callee($a{args}) => $callback:
					//switch callback.expr {
						//case EBinop(OpAssignOp(op), l, macro _):
							//callback = 
						//case EBinop(OpAssignOp(op), l, r):
							//callback = 
						//default:	
					//}
					macro @:pos(e.pos) $callee($a{args.concat([callback])});
				default: e;	
			}
	//static public function precedence(e:Expr) 
		//return
			//switch e.expr {
				//case EBinop(op, { expr: EMeta(s, lh) }, rh) if (op != OpArrow && (s.name == 'do' || s.name == 'f')):
					//EMeta(s, op.make(lh, rh, e.pos)).at(e.pos);
				//default: e;	
			//}
	static public function process(e:Expr) 
		return
			switch e {
				case { expr: EMeta({ name: name, params: [], pos: mpos }, { expr:ESwitch(macro _, cases, edef), pos:pos }) } if ('do,f'.indexOf(name) != -1):
					var tmp = String.tempName();
					process(EMeta( 
						{ name: name, params: [tmp.resolve()], pos: mpos },
						ESwitch(tmp.resolve(), cases, edef).at(pos)
					).at(e.pos));
				case macro ![$a{args}] => $body
					,macro @do($a{args}) $body:	
					var nuargs = [];
					
					for (arg in args)
						switch arg {
							case { expr: EVars(vars) }:
								for (v in vars) 
									nuargs.push(v.name.toArg(v.type, v.expr));
							case macro $i{name}: 
								nuargs.push(name.toArg());
							default: arg.reject('expected identifier or variable declaration');	
						}
					
					body.func(nuargs, false).asExpr(e.pos);
				case macro [$a{args}] => $body
					,macro @f($a{args}) $body:
					
					body.func([
						for (arg in args)
							arg.getIdent().sure().toArg()
					], true).asExpr(e.pos);
				default: e;
			}
}
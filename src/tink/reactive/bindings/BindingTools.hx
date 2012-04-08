package tink.reactive.bindings;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

import haxe.macro.Expr;
import haxe.macro.Type;
import tink.macro.tools.AST;

/**
 * ...
 * @author back2dos
 */

class BindingTools {
	@:macro static public function bindExpr(target:Expr, value:Expr) {
		var source = makeSource(value);
		var ret:Expr = AST.build({ 
			var tmpSrc = $source;
			var tmpUpdate = function () $target(tmpSrc.value);
			tmpSrc.watch(tmpUpdate);
			tmpUpdate();
			tmpSrc.value;//comes from cache so it should be cheap
		});
		return 
			if (ret.typeof().isSuccess()) ret;
			else 
				switch (target.expr) {
					case EField(e, field), EType(e, field):
						if (target.is(EDITABLE)) {
							if (!source.is(EDITABLE)) 
								source.reject('expression is not editable, although required by site property ' + field);
							else 
								target.assign(source);
						}
						else if (target.is(SOURCE))
							target.assign(source);
						else {
							var link = String.tempName();
							var init = 
								if (source.is(EDITABLE)) 
									AST.build(eval__link.twoway($source))
								else 
									AST.build(eval__link.single($source));
							AST.build({
								var tmp = $e;
								var eval__link = tink.reactive.bindings.Binding.Link.by(
									tmp, 
									"eval__field"
								);
								eval__link.init(
									function () return $target,
									function (tmpArg) return $target = tmpArg
								);
								$init;
							});
						}
					default:
						target.reject();
				}
	}
	#if macro
		static var SOURCE = 'tink.reactive.Source'.asComplexType([TPType('Dynamic'.asComplexType())]);
		static var EDITABLE = 'tink.reactive.Source.Editable'.asComplexType([TPType('Dynamic'.asComplexType())]);
		
		static function control(of:Expr) {
			return
				AST.build(
					new tink.reactive.bindings.Binding.Control(
						function () return $of, 
						function (tmp) return $of = tmp
					),
					of.pos
				);
		}
		static function makeSource(of:Expr):Expr {
			return
				if (of.is(SOURCE)) of;
				else 
					switch (of.typeof()) {
						case Success(_): 
							if (of.assign(of).typeof().isSuccess()) 
								control(of);
							else
								AST.build(
									new tink.reactive.bindings.Binding.Watch(
										function () return $of
									),
									of.pos
								);
						case Failure(f): f.throwSelf();
					}
		}
	#end
}
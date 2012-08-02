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
class FuncBindings {
	@:macro static public function bind<A>(func:ExprOf < A->Dynamic > , arg:ExprOf<A>) {
		var ret:Expr = AST.build({ 
			var tmpSrc = $(Helper.makeSource(arg));
			var tmpUpdate = function () $func(tmpSrc.value);
			tmpSrc.watch(tmpUpdate);
			tmpUpdate();
			tmpSrc.value;//comes from cache so it should be cheap
		});		
		return ret;
	}
}
class FieldBindings {
	@:macro static public function bind(owner:ExprOf<{}>, field:Expr, value:Expr) {
		var field = field.getName().sure(),
			source = Helper.makeSource(value);
			
		var target = owner.field(field);
		
		return
			if (target.is(Helper.EDITABLE)) {
				if (!source.is(Helper.EDITABLE)) 
					source.reject('expression is not editable, although required by site property ' + field);
				else 
					target.assign(source);
			}
			else if (target.is(Helper.SOURCE))
				target.assign(source);
			else {
				var link = String.tempName();
				var init = 
					if (source.is(Helper.EDITABLE)) 
						AST.build(eval__link.twoway($source))
					else 
						AST.build(eval__link.single($source));
				AST.build({
					var tmp = $owner;
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
		return target;
	}
}
#if macro
	private class Helper {
		static public var SOURCE = 'tink.reactive.Source'.asComplexType([TPType('Dynamic'.asComplexType())]);
		static public var EDITABLE = 'tink.reactive.Source.Editable'.asComplexType([TPType('Dynamic'.asComplexType())]);
		
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
		static public function makeSource(of:Expr):Expr {
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
	}
#end	
package tink.reactive.bindings;

#if macro
	using tink.macro.tools.MacroTools;
	using tink.core.types.Outcome;

	import haxe.macro.Expr;
	import haxe.macro.Type;
#end
class WatchHelper {
	macro static public function watch(e:Expr) {
		return (macro new tink.reactive.bindings.Binding.Watch(function () return $e)).finalize();
	}
}
class FuncBindings {
	macro static public function bind<A>(func:ExprOf < A->Dynamic > , arg:ExprOf<A>) {
		var src = Helper.makeSource(arg);
		return (macro { 
			var tmpSrc = $src;
			var tmpUpdate = function () $func(tmpSrc.value);
			tmpSrc.watch(tmpUpdate);
			tmpUpdate();
			tmpSrc.value;//comes from cache so it should be cheap
		}).finalize();
	}
}
class FieldBindings {
	macro static public function bind(owner:ExprOf<{}>, field:Expr, value:Expr) {
		var fieldName = field.getName().sure();
		var source = Helper.makeSource(value),
			target = owner.field(fieldName, field.pos);
		
		return
			if (target.is(Helper.EDITABLE)) {
				if (!source.is(Helper.EDITABLE)) 
					source.reject('expression is not editable, although required by site property ' + fieldName);
				else 
					target.assign(source);
			}
			else if (target.is(Helper.SOURCE))
				target.assign(source);
			else {
				var field = fieldName.toExpr(field.pos),
					init = 
						if (source.is(Helper.EDITABLE)) 
							macro tmpLink.twoway($source);
						else 
							macro tmpLink.single($source);
							
				(macro {
					var tmp = $owner;
					var tmpLink = tink.reactive.bindings.Binding.Link.by(
						tmp, 
						$field
					);
					tmpLink.init(
						function () return $target,
						function (tmpArg) return $target = tmpArg
					);
					$init;
				}).finalize();
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
				(macro
					new tink.reactive.bindings.Binding.Control(
						function () return $of, 
						function (tmp) return $of = tmp
					)
				).finalize(of.pos);
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
								(macro
									new tink.reactive.bindings.Binding.Watch(function () return $of)
								).finalize(of.pos);
						case Failure(f): f.throwSelf();
					}
		}
	}
#end	
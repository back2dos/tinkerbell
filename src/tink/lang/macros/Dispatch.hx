package tink.lang.macros;

import haxe.macro.Expr;

using tink.macro.tools.MacroTools;
using haxe.macro.ExprTools;
using tink.core.types.Outcome;

class Dispatch {
	static public function normalize(e:Expr)
		return switch e {
			case macro @until($a{args}) $handler:
				macro @:pos(e.pos) @when($a{args}) $handler;
			default: e;	
		}
	static var DISPATCHER = macro tink.lang.helpers.StringDispatcher;
	static public function on(e:Expr) 
		return
			switch e {
				case macro @when($a{args}) $handler:
					if (args.length == 0)
						e.reject('At least one signal/event/future expected');
					//var ret = ECheckType([for (arg in args) 
					var ret = [for (arg in args) 
						switch arg {
							case macro @capture $dispatcher[$event]
								,macro $dispatcher[@capture $event]:
								//TODO: allow for Iterable<String>
								macro @:pos(arg.pos) 
									$DISPATCHER.capture($DISPATCHER.promote($dispatcher), $event, ___h);
							case macro $dispatcher[$event]:
								macro @:pos(arg.pos) 
									$DISPATCHER.promote($dispatcher).watch($event, ___h);
							default:
								macro @:pos(arg.pos) $arg.when(___h);
								//macro @:pos(arg.pos) tink.core.types.Callback.target($arg)(___h);
						}
					//].toArray(), macro : tink.core.types.Callback.CallbackLink).at();
					].toArray();
					macro (function (___h) return $ret)($handler);//TODO: SIAF only generated because otherwise inference order will cause compiler error
				default: e;
			}
			
	static public function with(e:Expr) 
		return switch e {
			case macro @with($target) $handle:
				function transform(e:Expr) return switch e {
					case macro @with($_) $_: e;
					case macro @when($a{args}) $handler:
						args = 
							[for (arg in args) 
								switch arg.typeof() {
									case Success(t) if (t.getID() == 'String'):
										switch arg {
											case macro @capture $event: 
												macro @:pos(arg.pos) @capture ___t[$event];
											case event: 
												macro @:pos(arg.pos) ___t[$event];
										}
									default:
										switch arg {
											case macro $i{name}: 
												macro @:pos(arg.pos) ___t.$name;
											case macro $i{name}($a{args}): 
												macro @:pos(arg.pos) ___t.$name($a{args});
											default: arg;
										}
								}
							];
						handler = transform(handler);
						macro @when($a{args}) $handler;
					default: e.map(transform);
				}
				macro {
					var ___t = $target;
					${transform(handle)};
					___t;
				}
			default: e;
		}
}
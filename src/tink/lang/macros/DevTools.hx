package tink.lang.macros;

import haxe.macro.Expr;

using tink.macro.tools.MacroTools;

class DevTools {
	static public function explain(e:Expr)
		return switch e {
			case macro @:explain $e: e.log();
			default: e;
		}
	static public function log(e:Expr) 
		return switch e {
			case macro @log($a{args}) $value:				
				if (args.length > 0)
					args[0].pos.warning('arguments will be ignored');
				return macro @:pos(e.pos) {
					var x = $value;
					trace($v{value.toString()} + ': ' + x);
					x;
				}
			default: e;
		}
		
	static public function measure(e:Expr) 
		return switch e {
			case macro @measure($a{args}) $value:			
				var name = 
					switch args.length {
						case 0: e.pos.error('please supply a name for the benchmark');
						case 1: args[0];
						default: args[1].reject('too many arguments');
					}
				var count = 
					switch name {
						case macro $n * $count:
							name = n;
							count;
						default: 1.toExpr();
					}
				count.log();
				return (macro @:pos(e.pos) {
					var start = haxe.Timer.stamp(),
						name = $name,
						value = {
							for (___i in 0...$count - 1) $value; 
							[$value];//deals with Void
						}
					trace(name + ' took ' + Std.int(1000 * (haxe.Timer.stamp() - start)) + ' msecs');
					value[0];
				}).log();
			default: e;	
		}
		
}
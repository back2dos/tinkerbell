package tink.util;
import haxe.macro.Expr;
import tink.macro.tools.ExprTools;
using tink.macro.tools.ExprTools;
using tink.util.Outcome;
/**
 * ...
 * @author back2dos
 */

typedef Filter<A> = A->Bool; 

class FilterUtils {
	static public function eq<A>(value:A):Filter<A> {
		return function (a:A) return a == value;
	}
	static public inline function neq<A>(value:A):Filter<A> {
		return not(eq(value));
	}
	static public function not<A>(f:Filter<A>):Filter<A> {
		return function (a:A) return !f(a);
	}
	static public function or<A>(f1:Filter<A>, f2:Filter<A>):Filter<A> {
		return function (a:A) return f1(a) || f2(a);		
	}
	
	static public function one<A>(filters:Iterable<Filter<A>>):Filter<A> {
		return function (a:A) {
			for (filter in filters)
				if (filter(a)) 
					return true;
			return false;
		}
	}
	static public function all<A>(filters:Iterable<Filter<A>>):Filter<A> {
		return function (a:A) {
			for (filter in filters)
				if (!filter(a)) 
					return false;
			return true;
		}
	}
	
	static public function and<A>(f1:Filter<A>, f2:Filter<A>):Filter<A> {
		return function (a:A) return f1(a) && f2(a);		
	}
	
	//@:macro static public function on<A>(expr:ExprRequire<Filter<A>>, field:Expr):Expr {
		//var field = field.getName().data();
		//return ExprTools.ast(function (x) return $expr(x.eval__field));
	//}

}
package tink.macro.tools;

/**
 * ...
 * @author back2dos
 */
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using tink.macro.tools.ExprTools;

class TypeTools {
	static var types = new IntHash<Type>();
	static var idCounter = 0;
	
	@:macro static public function getType(id:Int):Type {
		return types.get(id);
	}		
	static public function toString(t:ComplexType) {
		return Printer.printType('', t);
	}
	static public function toType(t:ComplexType, ?pos) {	
		return [
			'_'.define(t, pos),
			'_'.resolve(pos)
		].toBlock(pos).typeof();
	}
	static public inline function reduce(type:Type) {
		return Context.follow(type);
	}
	static public function isVar(field:ClassField) {
		return switch (field.kind) {
			case FVar(_, _): true;
			default: false;
		}
	}
	static public function toComplex(type:Type):ComplexType {
		var id = idCounter++;
		types.set(id, type);
		return TPath({
			pack : ['haxe','macro'],
			name : 'MacroType',
			params : [TPExpr('tink.macro.tools.TypeTools.getType'.resolve().call([id.toExpr()]))],
			sub : null,				
		});		
	}	
}
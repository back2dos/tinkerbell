package tink.macro.tools;

/**
 * ...
 * @author back2dos
 */
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using tink.macro.tools.ExprTools;
using tink.util.Outcome;

class TypeTools {
	static var types = new IntHash<Type>();
	static var idCounter = 0;
	
	@:macro static public function getType(id:Int):Type {
		return types.get(id);
	}
	static public function getID(t:Type) {
		return
			switch (reduce(t)) {
				case TInst(t, _): t.toString();
				case TEnum(t, _): t.toString();
				default: null;
			}
	}
	static public function getFields(t:Type) {
		return
			switch (reduce(t)) {
				case TInst(t, _): t.get().fields.get().asSuccess();
				case TAnonymous(anon): anon.get().fields.asSuccess();
				default: 'type has no fields'.asFailure();
			}
	}
	
	static function isIterator(t:Type) {
		return
			switch (getFields(t)) {
				case Success(fields): 
					var count = 0;//TODO: make this stricter
					for (field in fields)
						switch (field.name) {
							case 'hasNext': count++;
							case 'next': count++;
						}
					count == 2;
				default: false;
			}
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
	static public function asTypePath(s:String, ?params, ?sub) {
		var parts = s.split('.');
		return TPath({
			name: parts.pop(),
			pack: parts,
			params: params == null ? [] : params,
			sub: sub
		});
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
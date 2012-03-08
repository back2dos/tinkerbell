package tink.collections;

/**
 * ...
 * @author back2dos
 */
#if macro
	import haxe.macro.Expr;
	import tink.macro.tools.AST;
	using tink.macro.tools.MacroTools;
	using tink.core.types.Outcome;
#end
class MapTools {
	static public function pairs < K, V > (source:Map < K, V > ):Iterator<{key:K, val:V}> {
		var keys = source.keys(),
			vals = source.iterator();
		return {
			hasNext: function () return keys.hasNext(),
			next: function () return {
				key: keys.next(),
				val: vals.next()
			}
		}
	}

	@:macro static public function zip < K, V > (keys:ExprRequire<Iterable<K>>, values:ExprRequire<Iterable<V>>) {
		var keyType = keys.isIterable().sure();
		var params = [TPType(keyType.toComplex()), TPType(values.isIterable().sure().toComplex())];
		var map = 
			switch (keyType.reduce()) {
				case TEnum(e, _): 
					if (keyType.getID() == 'Bool') {
						params.shift(); 
						'AnyMap';//TODO: unlazify
					}
					else 'ObjectMap';
				case TInst(_, _): 
					switch (keyType.getID()) {
						case 'Int': params.shift(); 'IntMap';
						case 'String': params.shift(); 'StringMap';
						case 'Float': params.shift();  'AnyMap';//TODO: unlazify
						default: 'ObjectMap';
					}
				case TFun(_): 'FunctionMap';
				case TAnonymous(_): 'ObjectMap';
				case TDynamic(_): 'AnyMap';
				default: keys.pos.error('failed to abstract type from this collection');
			}
		var create = ENew( { pack: ['tink', 'collections'], name: map, params: params, sub:null }, []).at(keys.pos);
		
		return AST.build( {
			var tmpMap = $create;
			var tmpVals = $values.iterator();
			for (tmpKey in $keys)
				tmpMap.set(tmpKey, tmpVals.hasNext() ? tmpVals.next() : null);
			tmpMap;
		});
	}
}
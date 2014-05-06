package tink.collections.maps;

#if macro
	import haxe.macro.Context;
	import haxe.macro.Expr;
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

	macro static public function zip < K, V > (keys:ExprOf<Iterable<K>>, values:ExprOf<Iterable<V>>) {
		var keyType = keys.getIterType().sure();
		var params = [TPType(keyType.toComplex()), TPType(values.getIterType().sure().toComplex())];
		var map = 
			switch (keyType.getID()) {
				case 'Bool':
					params.shift(); 
					'AnyMap';//TODO: unlazify
				case 'Int': params.shift(); 'IntMap';
				case 'String': params.shift(); 'StringMap';
				case 'Float': params.shift();  'AnyMap';//TODO: unlazify
				default:
					switch (keyType.reduce()) {
						case TEnum(_, _): 'ObjectMap';
						case TInst(_, _): 'ObjectMap';
						case TFun(_): 'FunctionMap';
						case TAnonymous(_): 'ObjectMap';
						case TDynamic(_): 'AnyMap';
						default: keys.pos.error('failed to base type from this collection');
					}
			}
		var create = ENew( { pack: 'tink.collections.maps'.split('.'), name: map, params: params, sub:null }, []).at(keys.pos);
		
		return (macro {
			var map = $create,
				vals = $values.iterator(),
				keys = $keys;
			for (key in keys)
				map.set(key, vals.hasNext() ? vals.next() : null);
			map;
		}).finalize(null);
	}
}
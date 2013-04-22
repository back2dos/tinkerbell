package tink.macro.tools;

import haxe.macro.Expr;

class MetadataTools {	
	static public function toMap(m:Metadata) {
		var ret = new Map<String,Array<Array<Expr>>>();
		for (meta in m) {
			if (!ret.exists(meta.name))
				ret.set(meta.name, []);
			ret.get(meta.name).push(meta.params);
		}
		return ret;
	}
	
	static public function getValues(m:Metadata, name:String)
		return [for (meta in m) 
			if (meta.name == name) meta.params
		];	
}
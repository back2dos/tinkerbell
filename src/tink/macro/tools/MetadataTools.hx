package tink.macro.tools;

import haxe.macro.Expr;

class MetadataTools 
{	
	static public function toHash(m:Metadata)
	{
		var ret = new Hash<Array<Array<Expr>>>();
		for (meta in m)
		{
			if (!ret.exists(meta.name))
				ret.set(meta.name, []);
			ret.get(meta.name).push(meta.params);
		}
		return ret;
	}
	
	static public function getValues(m:Metadata, name:String)
	{
		var ret = [];
		for (meta in m)
		{
			if (meta.name == name)
				ret.push(meta.params);
		}
		return ret;		
	}
	
}
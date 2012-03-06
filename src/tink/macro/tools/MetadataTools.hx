package tink.macro.tools;

import haxe.macro.Expr;

class MetadataTools 
{	
	static public function toHash(m:Metadata)
	{
		var ret = new Hash<Array<Expr>>();
		for (meta in m)
		{
			if (!ret.exists(meta.name))
				ret.set(meta.name, []);
			for (param in meta.params)
				ret.get(meta.name).push(param);
		}
		return ret;
	}
	
	static public function getValues<S, T>(m:Metadata, name:String)
	{
		var ret = [];
		for (meta in m)
		{
			if (meta.name == name)
			{
				for (param in meta.params)
					ret.push(param);
			}
		}
		return ret;		
	}
	
}
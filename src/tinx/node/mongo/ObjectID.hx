package tinx.node.mongo;

import tink.core.types.Outcome;
import tinx.node.Error;
import tinx.node.Runtime;

@:native('require("mongodb").ObjectID')
private extern class Native {
	function new(?s:String);
	function toString():String;
}
abstract ObjectID(Native) {
	public function new(?s:String) this = new Native(s); 
	@:to public function toString():String return this.toString();
	static public function parse(s:String):Outcome < ObjectID, Error > {
		try {
			return Success(new ObjectID(s));
		}
		catch (e:Dynamic) 
			return Failure(e);
	}
	@:to public function toDate():Date {
		return Date.fromTime((untyped parseInt)(this.toString().substr(0,8), 16)*1000);
	}
}
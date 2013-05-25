package tinx.node.mongo;

@:native('require("mongodb").ObjectID')
extern class ObjectID {
	public function new(?s:String):Void;
	public function toString():String;
	public function valueOf():String;
	static public inline function gen():String return new ObjectID().valueOf();		
}
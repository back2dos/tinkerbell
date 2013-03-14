package tinx.node.mongo;

@:native('require("mongodb").ObjectId')
extern class ObjectID {
	public function new():Void;
	public function toString():String;
}
package tinx.node.mongo;

@:native('require("mongodb").ObjectId')
class ObjectID {
	public function new() {
		
	}
	@:extern public function toString():String;
}
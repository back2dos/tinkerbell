package tinx.node.mongo;

import tinx.node.mongo.Internal;

typedef DynCollection = Collection<Dynamic>;

@:verbose class DynDb extends DbBase implements Dynamic<DynCollection> {
	public function resolve<A>(name:String):Collection<A>
		return collection(name);
}
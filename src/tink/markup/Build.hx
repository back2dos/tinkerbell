package tink.markup;

/**
 * ...
 * @author back2dos
 */

@:macro class Build {
	static public function fast(e) {
		return TreeCrawler.build(e, new Fast());
	}
	static public function xml(e) {
		return TreeCrawler.build(e, new Nodes());
	}
}
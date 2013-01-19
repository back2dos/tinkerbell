package tink.markup;

#if macro
	import tink.markup.formats.Fast;
	import tink.markup.formats.Nodes;
	import tink.markup.formats.Tags;
	import tink.markup.formats.TreeCrawler;	
#end

class Build {
	macro static public function fast(e) {
		return TreeCrawler.build(e, new Tags(new Fast()));
	}
	macro static public function xml(e) {
		return TreeCrawler.build(e, new Tags(new Nodes()));
	}
}
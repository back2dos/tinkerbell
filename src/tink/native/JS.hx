package tink.native;

import tink.util.Embed;

class JS {
	static public function patchBind() {
		untyped __js__(Embed.stringFromFile('cachedbind.js'));
	}
	static public function getID() {
		return 0;
	}
}
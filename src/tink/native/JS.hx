package tink.native;

import tink.util.Embed;

@:native('__helpers')
class JS {
	static public function patchBind() {
		untyped __js__(Embed.stringFromFile('cachedbind.js'));
	}
}
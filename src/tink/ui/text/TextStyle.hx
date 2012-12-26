package tink.ui.text;

import flash.text.TextFormat;
import tink.lang.Cls;

class TextStyle implements Cls {
	@:bindable var font = '_sans'; 
	@:bindable var color = 0x000000;
	@:bindable var bold = false;
	@:bindable var italic = false;
	@:bindable var size = 12.0;
	@:bindable var embed = false;
	public function new() { }
	public function toNative() {
		return new TextFormat(font, size, color, bold, italic);
	}
}
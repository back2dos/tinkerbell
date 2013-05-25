package tinx.nw;

import js.Browser;
import tink.core.types.Signal;
import tinx.dom.Node;

class App {
	static public var argv(default, null) = NativeUI.App.argv;
	static public function quit(?force:Bool):Void {
		if (force) NativeUI.App.quit();
		else NativeUI.App.closeAllWindows();
	}
	static public var fileOpened(default, null) = new Signal(
		function (cb) {
			var f = function (s:String) cb.invoke(s);
			NativeUI.App.addListener('open', f);
			return NativeUI.App.removeListener.bind('open', f);
		}
	);
	static function browse() {
		var e = Browser.document.createInputElement();
		e.type = "file";
		e.click();
		return Node.of(e).events.change.next().map(function (_) return e.value);
	}		
}
package tink.ui.core;
import flash.display.DisplayObject;
import tink.ui.core.Metrics;

/**
 * ...
 * @author back2dos
 */

interface UILeaf {
	function getMetrics():Metrics;
	function getView():DisplayObject;
	//function getParent():UINode;
	//private function __setParent(param:UINode):Void;
}
//private typedef Friend = {
	//private function __setParent(param:UINode):Void;	
//}
//class UILeafTools {
	//static public inline function setParent(target:Friend, param) {
		//target.__setParent(param);
	//}
//}
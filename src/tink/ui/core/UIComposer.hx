package tink.ui.core;

/**
 * ...
 * @author back2dos
 */

class UIComposer<V:DisplayObject, S:Style, T:UIComponent<V, S>> implements UILeaf {
	var target:T = _;
	@:read(target.style) var style:S;
	private function new() {}
	public function getMetrics() 
		return target.getMetrics()
	public function getView() 
		return target.getView()
}
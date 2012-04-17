package tink.ui.core;

import tink.lang.Cls;
import tink.reactive.bindings.BindableArray;
import tink.ui.core.Metrics;

import tink.ui.core.UILeaf;

using tink.ui.core.UILeaf;

/**
 * ...
 * @author back2dos
 */

class UIStack implements Cls, implements UINode {
	var children = new BindableArray<UILeaf>();
	public function new() {}
	public function addChild(child:UILeaf) {
		var parent = child.getParent();
		if (parent != null) 
			parent.removeChild(child);
		this.children.push(child);
	}
	public function removeChild(child:UILeaf):Bool {
		return child.getParent() == this && children.remove(child);
	}
	public function getMetrics():Metrics {
		return null;
	}
	public function getParent():UINode {
		return null;
	}
	
}
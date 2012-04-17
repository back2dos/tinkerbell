package tink.ui.core;

/**
 * ...
 * @author back2dos
 */

interface UINode implements UILeaf {
	function removeChild(child:UILeaf):Bool;
}
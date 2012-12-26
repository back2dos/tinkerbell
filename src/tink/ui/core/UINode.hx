package tink.ui.core;

interface UINode implements UILeaf {
	function removeChild(child:UILeaf):Bool;
}
package tink.ui.core;

import tink.reactive.Source;
import tink.ui.style.Style;

import flash.display.DisplayObject;

/**
 * ...
 * @author back2dos
 */

interface UIView<D:Source> extends UILeaf { }
interface UIControl<D:Editable> extends UILeaf { }
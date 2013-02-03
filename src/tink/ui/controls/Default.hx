package tink.ui.controls;

using tink.macro.tools.MacroTools;

class Default {
	macro static public function or(value, fallback) {
		return (macro {
			var tmp = $value;
			if (tmp == null) 
				$fallback;
			else 
				tmp;
		}).finalize();
	}
}
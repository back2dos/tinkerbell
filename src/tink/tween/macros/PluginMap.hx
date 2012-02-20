package tink.tween.macros;

/**
 * ...
 * @author back2dos
 */
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using tink.macro.tools.MacroTools;

class PluginMap {
	static var plugins = new Hash<PluginStack>();
	@:macro static public function register():Array<Field> {
		var cl = Context.getLocalClass().get();
		if (cl.isInterface) return null;
		if (cl.params.length > 0) return null;
		var current = cl,
			t = null;
		while (t == null) {
			for (i in current.interfaces) {
				if (i.t.get().name == 'Plugin') {
					t = i.params[0];
					break;
				}
			}
			if (t == null) {
				if (current.superClass == null) 
					cl.pos.error('unable to determine plugin type');
				current = current.superClass.t.get();				
			}
		}		
			
		var name = cl.name.charAt(0).toLowerCase() + cl.name.substr(1);
		var stack = plugins.get(name);
		if (stack == null)
			plugins.set(name, stack = new PluginStack());
		stack.add(cl);
		return null;
	}
	static public function getPluginFor(e:Expr, prop:String) {
		return 
			if (plugins.exists(prop))
				plugins.get(prop).getPlugin(e);
			else
				null;
	}
}
private class PluginStack {
	var filters:Array<ComplexType>;
	var plugins:Array<TypePath>;
	public function new() {
		this.filters = [];
		this.plugins = [];
	}
	public function add(cl:ClassType) {
		var path = cl.module.split('.');
		var t = {
			name : path.pop(),
			pack : path,
			params : [],
			sub : cl.name,
		};
		this.filters.push(cl.superClass.params[0].toComplex());
		this.plugins.push(t);
	}
	public function getPlugin(target:Expr) {
		var i = 0;
		for (f in filters) {
			if (target.is(f))
				return plugins[i];
			i++;
		}
		return null;
	}
}
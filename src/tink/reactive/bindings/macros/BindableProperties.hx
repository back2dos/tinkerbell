package tink.reactive.bindings.macros;

import tink.lang.macros.PropBuilder;
import tink.macro.build.Member;
import tink.macro.build.MemberTransformer;
import tink.macro.tools.AST;
import haxe.macro.Expr;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
using Lambda;
/**
 * ...
 * @author back2dos
 */

class BindableProperties {
	static public inline var IS_BINDABLE = 'bindable';
	static public inline var BINDABLE = ':bindable';
	static public inline var CACHE = ':cache';
	
	static function getter(name:String, pos:Position) {
		return 
			AST.build({ 
				this.bindings.byString.bind("eval__name");
				this.eval__name;
			}, pos);
	}
	static function setter(name:String, pos:Position) {
		return 
			AST.build({ 
				this.bindings.byString.fire("eval__name", this.eval__name = param);
			}, pos);
	}
	static function makeBinding(on:Expr) {
		switch (on.typeof().sure().reduce().getID()) {
			case 'String': return macro this.bindings.byString.bind($on);
			case 'Int': return macro this.bindings.byInt.bind($on);
			case 'Bool': return macro this.bindings.byBool.bind($on);
			default: return macro this.bindings.byUnknown.bind($on);
		}
		return on;
	}
	static public function make(ctx:ClassBuildContext) {
		function makeBindable(pos) 
			if (!ctx.has('bindings')) {
				ctx.add(Member.plain('bindings', 'tink.reactive.bindings.Binding.Signaller'.asComplexType(), pos));
				ctx.getCtor().init('bindings', pos, AST.build(new tink.reactive.bindings.Binding.Signaller(), pos), true);
			}
		var setters = new Hash(),
			getters = new Hash();
		for (member in ctx.members) {
			switch (member.extractMeta(BINDABLE)) {
				case Success(tag):
					makeBindable(tag.pos);
					if (member.isPublic == null) 
						member.publish();
					member.addMeta(IS_BINDABLE, tag.pos);
					var name = member.name;
					switch (member.kind) {
						case FVar(t, _):
							PropBuilder.make(member, t, getter(name, tag.pos), setter(name, tag.pos), ctx.has, ctx.add);
						case FProp(get, set, t, _):
							var nonCustom = 'default,never,null'.split(',');
							if (nonCustom.has(get)) 
								tag.pos.error('cannot make non-custom read access bindable');
							else
								getters.set(get, name);
							if (nonCustom.has(set)) {
								if (set == 'default')
									tag.pos.error('cannot make non-custom write access bindable');
							}
							else 
								setters.set(set, name);
						case FFun(f):
							var body = [];
							for (key in [name.toExpr(tag.pos)].concat(tag.params))
								//body.push(AST.build(bindings.bind($key), key.pos));
								body.push(callback(makeBinding, key).bounce(key.pos));
							body.push(f.expr);
							f.expr = body.toBlock(tag.pos);
					}
				default:
			}
			switch (member.extractMeta(CACHE)) {
				case Success(tag):
					if (member.isPublic == null) 
						member.publish();
					member.addMeta(IS_BINDABLE, tag.pos);
					var name = member.name;
					switch (member.kind) {
						case FVar(t, _):
							var cacheName = '__tink_reactive_cache__' + name,
								bindingType = 'tink.reactive.bindings.Binding.Watch'.asComplexType([TPType(t)]);
								
							ctx.add(Member.plain(cacheName, bindingType, tag.pos));
							var expr = 
								switch (tag.params.length) {
									case 1: tag.params[0];
									default: tag.pos.error('tag requires 1 argument exactly');
								}
							
							ctx.getCtor().init(
								cacheName, 
								tag.pos, 
								AST.build(new tink.reactive.bindings.Binding.Watch(function () return $expr), tag.pos), 
								true,
								bindingType
							);
							ctx.add(Member.getter(name, tag.pos, AST.build(eval__cacheName.value, tag.pos), t));
							member.kind = FProp('get_' + name, 'null', t);
						default: 
							member.pos.error('');
					}
				default:
			}
		}
		for (member in ctx.members) {
			if (setters.exists(member.name)) {
				var f = member.getFunction().sure();
				f.expr = f.expr.transform(injectFire(setters.get(member.name)));
			}
			else if (getters.exists(member.name)) {
				var f = member.getFunction().sure();
				f.expr = f.expr.transform(injectBind(getters.get(member.name)));			
			}
		}
	}
	static function injectFire(name:String) {
		return
			callback(function (name:String, e:Expr) 
				return
					switch (e.expr) {
						case EReturn(e): AST.build(return this.bindings.byString.fire("eval__name", $e), e.pos);
						default: e;
					}
				,name		
			);
	}
	static function injectBind(name:String) {
		return
			callback(function (name:String, e:Expr) 
				return
					switch (e.expr) {
						case EReturn(e): AST.build(return this.bindings.byString.bind("eval__name", $e), e.pos);
						default: e;
					}
				,name
			);		
	}
	
}
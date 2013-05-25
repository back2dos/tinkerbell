package tink.reactive.bindings.macros;

import tink.lang.macros.PropBuilder;
import tink.macro.build.Member;
import tink.macro.build.MemberTransformer;
import haxe.macro.Expr;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
using Lambda;

class BindableProperties {
	static public inline var IS_BINDABLE = 'bindable';
	static public inline var BINDABLE = ':bindable';
	static public inline var CACHE = ':cache';
	
	static function getter(name:String, pos:Position) {
		var str = name.toExpr(pos),
			field = ['this', name].drill(pos);
		return 
			(macro {
				this.bindings.byString.bind($str);
				$field;
			}).finalize(pos);
	}
	static function setter(name:String, pos:Position) {
		var str = name.toExpr(pos),
			field = ['this', name].drill(pos);
		return 
			(macro { 
				this.bindings.byString.fire($str, $field = param);
			}).finalize(pos);
	}
	static function makeBinding(on:Expr, BINDINGS:Expr) {
		return 
			(switch (on.typeof().sure().reduce().getID()) {
					case 'String': macro $BINDINGS.byString.bind($on);
					case 'Int': macro $BINDINGS.byInt.bind($on);
					case 'Bool': macro $BINDINGS.byBool.bind($on);
					default: macro $BINDINGS.byUnknown.bind($on);
				}
			).finalize(on.pos);
	}
	
	static public function cache(ctx:ClassBuildContext) {		
		for (member in ctx.members) 
			switch (member.extractMeta(CACHE)) {
				case Success(tag):
					if (member.isPublic == null) 
						member.publish();
					member.addMeta(IS_BINDABLE, tag.pos);
					var name = member.name;
					switch (member.kind) {
						case FVar(t, e):
							if (t == null)
								t = member.pos.makeBlankType();
							var cacheName = '__tink_reactive_cache__' + name,
								bindingType = 'tink.reactive.bindings.Binding.Watch'.asComplexType([TPType(t)]);
							ctx.add(Member.plain(cacheName, bindingType, tag.pos)).addMeta(':noCompletion');
							var expr = 
								switch (tag.params.length) {
									case 0: 
										if (e == null) tag.pos.error('no implementation specified');
										else e;
									case 1: 
										if (e == null) {
											tag.params[0].pos.warning('syntax is deprecated');
											tag.params[0];
										}
										else tag.params[0].reject('cannot define implementation through metadata and =');
									default: tag.pos.error('too many arguments');
								}
							
							ctx.getCtor().init(
								cacheName, 
								tag.pos, 
								macro @:pos(tag.pos) new tink.reactive.bindings.Binding.Watch(function () return $expr), 
								true,
								bindingType
							);
							var cache = cacheName.resolve(tag.pos);
							ctx.add(Member.getter(name, tag.pos, macro $cache.value, t)).addMeta(':noCompletion');
							member.kind = FProp('get_' + name, 'null', t);
						default: 
							member.pos.error('cache only works on variables');
					}
				default:
			}
	}
	
	static var BINDINGS = null;
	static public function make(ctx:ClassBuildContext) {
		BINDINGS = 
			switch (ctx.cls.kind) {
				case KAbstractImpl(_): macro get_bindings();
				default: macro this.bindings;
			}
			
		function makeBindable(pos) 
			if (!ctx.has('bindings')) {
				ctx.add(Member.plain('bindings', 'tink.reactive.bindings.Binding.Signaller'.asComplexType(), pos));
				ctx.getCtor().init('bindings', pos, (macro new tink.reactive.bindings.Binding.Signaller()).finalize(pos), true);
			}
		var setters = new Map(),
			getters = new Map();
		for (member in ctx.members) 
			switch (member.extractMeta(BINDABLE)) {
				case Success(tag):
					makeBindable(tag.pos);
					member.publish();
					member.addMeta(IS_BINDABLE, tag.pos);
					var name = member.name;
					switch (member.kind) {
						case FVar(t, _):
							member.addMeta(':isVar', tag.pos);
							PropBuilder.make(member, t, getter(name, tag.pos), setter(name, tag.pos), ctx.has, ctx.add);
						case FProp(get, set, _, _):
							var nonCustom = 'default,never,null'.split(',');
							if (nonCustom.has(get)) 
								tag.pos.error('cannot make non-custom read access bindable');
							else
								getters.set('get_' + member.name, name);
							if (nonCustom.has(set)) {
								if (set == 'default')
									tag.pos.error('cannot make non-custom write access bindable');
							}
							else 
								setters.set('set_' + member.name, name);
						case FFun(f):
							var body = [];
							for (key in [name.toExpr(tag.pos)].concat(tag.params))
								body.push(makeBinding.bind(key, BINDINGS).bounce(key.pos));
							body.push(f.expr);
							f.expr = body.toBlock(tag.pos);
					}
				default:
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
			function (e:Expr) 
				return
					switch (e.expr) {
						case EReturn(e): 
							var name = name.toExpr(e.pos);
							macro @:pos(e.pos) return $BINDINGS.byString.fire($name, $e);
						default: e;
					}
	}
	static function injectBind(name:String) {
		return
			function (e:Expr) 
				return
					switch (e.expr) {
						case EReturn(e): 
							var name = name.toExpr(e.pos);
							macro @:pos(e.pos) return $BINDINGS.byString.bind($name, $e);
						default: e;
					}
	}
	
}
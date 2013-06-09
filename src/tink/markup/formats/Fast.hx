package tink.markup.formats;
#if macro
	import haxe.macro.Context;
	import haxe.macro.Expr;
	import haxe.macro.Format;

	using tink.macro.tools.MacroTools;
	using tink.core.types.Outcome;
	
	class Fast {
		var here:Position;
		var tmp:String;
		public function new() {
			here = Context.currentPos();
			tmp = String.tempName();
		}
		public function init(pos:Position):Null<Expr> {
			return null;
		}
		public function finalize(pos:Position):Null<Expr> {
			return null;
		}
		public function defaultTag(pos:Position):Expr {
			return 'div'.toExpr(pos);
		}
		function flatten(e:Expr) {
			return
				switch (e.expr) {
					case EBlock(exprs):
						var ret = [];
						for (e in exprs) 
							switch (e.expr) {
								case EBlock(exprs): ret = ret.concat(exprs);
								default: ret.push(e);
							}
						ret.toBlock(e.pos);
					default: e;
				}
		}
		function unify(e:Expr) {
			return
				switch (e.expr) {
					case EBlock(exprs):
						var buf = new StringBuf();
						var ret = [];
						function flush() {
							var s = buf.toString();
							buf = new StringBuf();
							if (s.length > 0)
								ret.push(sOut(s));
						}
						for (e in exprs) {
							switch (e.match(IS_LITERAL)) {
								case Success(m):
									buf.add(m.strings.lit);
								default:
									flush();
									ret.push(e);
							}
						}
						flush();
						ret.toBlock(e.pos);
					default: e;
				}
		}
		function print(e:Expr) {
			return
				switch (e.match(IS_OUT)) {
					case Success(m):
						tmp.resolve().field('add').call([m.exprs.v]);
					default: e;
				}
		}
		function optimize(target:Expr) {
			target = target.transform(flatten).transform(unify).transform(print);
			return wrap(target);
		}
		function wrap(target:Expr) {
			//target = target.withPrivateAccess();
			var f = target.func([tmp.toArg()], false).asExpr();
			return (macro new tink.markup.formats.Fast($f)).finalize(target.pos);			
		}
		public function postprocess(e:Expr):Expr 
			return 
				//if (Context.defined('display'))
					//wrap(e);
				//else 
					e.outerTransform(optimize);
		
		function sOut(s:String):Expr {
			return out(s.toExpr(here));
		}
		static function out(e:Expr):Expr {
			return (macro tink.markup.formats.Fast.add($e)).finalize(e.pos);
		}
		static var IS_LITERAL = out(EConst(CString("NAME__lit")).at());//TODO: using toExpr or $v{} causes compiler error
		static var IS_OUT = out("EXPR__v".resolve());
		public function setProp(attr:String, value:Expr, pos:Position):Expr {
			return [
				sOut((' ' + attr + '="')),
				out(value),
				sOut('"')
			].toBlock(pos);
		}
		public function addString(s:String, pos:Position):Expr {
			return sOut(s);
		}
		public function addChild(e:Expr, ?t:Type):Expr {
			return out(e);
		}
		public function buildNode(nodeName:Expr, props:Array<Expr>, children:Array<Expr>, pos:Position, yield:Expr->Expr):Expr {
			var ret = [];
			ret.push(sOut('<'));
			ret.push(out(nodeName));
			for (p in props)
				ret.push(yield(p));
			if (children.length > 0) {
				ret.push(sOut('>'));
				for (c in children)
					ret.push(yield(c));
				ret.push(sOut('</'));
				ret.push(out(nodeName));
				ret.push(sOut('>'));
			}
			else 
				ret.push(sOut(' />'));
			return ret.toBlock();
		}
		static public function build(e:Expr) 
			return
				switch (e.expr) {
					case EMeta( { name : 'html', params: [] }, e):
						e = TreeCrawler.build(e, new Tags(new Fast()));
						macro @:pos(e.pos) $e.toString();
					default: e;
				}
	}
#else
	class Fast {
		var out:StringBuf->Void;
		public function new(out) {
			this.out = out;
		}
		public inline function printTo(buf:StringBuf) {
			out(buf);
			return buf;
		}
		public function toString():String {
			return printTo(new StringBuf()).toString();
		}
		static public function add(d:Dynamic):Void {
			return null;
		}
	}
#end
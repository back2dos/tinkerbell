package tink.macro.build;

import haxe.macro.Expr;
import tink.macro.tools.ExprTools;

using tink.macro.tools.MacroTools;

class Constructor {
	var oldStatements:Array<Expr>;
	var nuStatements:Array<Expr>;
	var beforeArgs:Array<FunctionArg>;
	var args:Array<FunctionArg>;
	var afterArgs:Array<FunctionArg>;
	var pos:Position;
	var ownerIsInterface:Bool;
	public var isPublic:Bool;
	public function new(ownerIsInterface:Bool, f:Function, ?isPublic:Null<Bool> = null, ?pos:Position) {
		this.ownerIsInterface = ownerIsInterface;
		this.nuStatements = [];
		this.isPublic = isPublic;
		this.pos = pos.getPos();
		
		this.args = [];
		this.beforeArgs = [];
		this.afterArgs = [];
		
		if (f == null) {
			this.oldStatements = [];
		}
		else {
			for (i in 0...f.args.length) {
				var a = f.args[i];
				if (a.name == '_') {
					afterArgs = f.args.slice(i + 1);
					break;
				}
				beforeArgs.push(a);
			}
				
			this.oldStatements =
				if (f.expr == null) [];
				else
					switch (f.expr.expr) {
						case EBlock(exprs): exprs;
						default: oldStatements = [f.expr]; 
					}
		}
	}
	public function init(name:String, pos:Position, ?e:Expr, ?def:Expr, ?prepend:Bool, ?t:ComplexType) {
		if (ownerIsInterface) pos.error('cannot initialize properties on interfaces');
		if (e == null) {
			e = name.resolve(pos);
			args.push( { name : name, opt : def != null, type : null, value : def } );
			if (isPublic == null) 
				isPublic = true;
		}
		if (t != null)
			e = ECheckType(e, t).at(e.pos);
		var s = EUntyped('this'.resolve(pos)).at(pos).field(name, pos).assign(e, pos);
			
		if (prepend)
			this.nuStatements.unshift(s);
		else
			this.nuStatements.push(s);
	}
	public inline function publish() {
		if (isPublic == null) 
			isPublic = true;
	}
	public function toBlock() {
		return nuStatements.concat(oldStatements).toBlock(pos);
	}
	public function toHaxe() {
		return {
			name: 'new',
			doc : null,
			access : isPublic ? [APublic] : [],
			kind :  FFun( {
				args: this.beforeArgs.concat(this.args).concat(this.afterArgs),
				ret: 'Void'.asComplexType(),
				expr: toBlock(),
				params: []
			}),
			pos : pos,
			meta : []
		}
	}
}
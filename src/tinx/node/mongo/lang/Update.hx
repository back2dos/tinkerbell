package tinx.node.mongo.lang;

using Type;
import haxe.ds.StringMap;
import haxe.macro.Context;
import haxe.macro.Expr;

using tink.macro.tools.MacroTools;
using StringTools;
using Lambda;

typedef DocUpdate = Array<FieldUpdate>;
typedef FieldUpdate = {
	field:Path,
	op:FieldUpdateOp
}
enum FieldUpdateOp {
	Set(v:Expr);
	Inc(v:ExprOf<Float>);
	Unset;
	BitOr(v:ExprOf<Int>);
	BitAnd(v:ExprOf<Int>);
	BitXor(v:ExprOf<Int>);
	Push(values:Array<Expr>);
	Pull(values:Array<Expr>);
	AddToSet(values:Array<Expr>);
	Pop(?shift:Bool);
}
private class Parser {
	static public function parse(a:Array<Expr>):DocUpdate
		return [for (f in a) field(f)];
	
	static function make(path, op):FieldUpdate
		return {
			field: Path.of(path),
			op: op
		}
		
	static function field(e:Expr) 
		return
			switch (e.expr) {
				case EUnop(OpIncrement, true, path): make(path, Inc(macro 1));
				case EUnop(OpDecrement, true, path): make(path, Inc(macro -1));
				case EUnop(OpNot, false, path): make(path, Unset);
				case EBinop(OpAssign, path, v): make(path, Set(v));
				case EBinop(OpAssignOp(op), path, v):
					switch (op) {
						case OpAdd: make(path, Inc(v));
						case OpSub: make(path, Inc(OpNeg.make(v)));
						case OpOr, OpAnd, OpXor: 
							make(path, FieldUpdateOp.createEnum(op.enumConstructor().replace('Op', 'Bit'), [v]));
						default: e.reject('cannot handle operation $op');
					}
				case ECall( { expr: EField(path, op) }, params):
					make(
						path,
						switch (op) {
							case 'pop', 'shift': 
								if (params.length != 0)
									e.reject('$op must not have any arguments');
								Pop(op == 'shift');
							case 'push': Push(params); 
							case 'remove': Pull(params); 
							case 'add': AddToSet(params);
							default: e.reject('unknown operation $op');
						}
					);
				default: e.reject();
			}
}
private class Generator {
	var ops:StringMap<StringMap<Expr>>;
	public function new(d:DocUpdate) {
		ops = new StringMap();
		for (f in d)
			switch (f.op) {
				case Pop(shift):
					fieldOp('pop', f.field, shift ? macro -1 : macro 1);
				case Unset:
					fieldOp('unset', f.field, macro 1);
				case Set(v), Inc(v), AddToSet([v]):
					fieldOp(f.op.enumConstructor(), f.field, v);
				case AddToSet(values):
					fieldOp('addToSet', f.field, macro { "$each" : $a{values} } );
				case BitAnd(v), BitOr(v), BitXor(v):
					fieldOp('bit', f.field, EObjectDecl([field(f.op.enumConstructor().substr(3), v)]).at());
				case Push(values), Pull(values):
					var opName = f.op.enumConstructor();
					var e = 
						if (values.length == 1) values[0];
						else {
							opName += 'All';
							values.toArray();
						}
					fieldOp(opName, f.field, e);
			}
	}
	function fieldOp(opName:String, path:Path, expr) {
		opName = opName.charAt(0).toLowerCase() + opName.substr(1);
		if (!ops.exists(opName)) 
			ops.set(opName, new StringMap());
		var op = ops.get(opName);
		var name = path.join('.');
		if (op.exists(name))
			path.last.pos.error('duplicate $opName for $name');
		op.set(name, expr);
	}
	function field(name, expr)
		return {
			field: name,
			expr: expr
		}
		
	function genOp(op:StringMap<Expr>) 
		return 
			EObjectDecl([
				for (name in op.keys()) 
					field(name, op.get(name))
			]).at();
		
	public function gen() {
		return EObjectDecl([
			for (opName in ops.keys()) 
				field(
					'$'+opName, 
					genOp(ops.get(opName))
				)
		]).at();
	}
}
private class Typer {
	static public function type(f:FieldUpdate, t:TypeInfo) {
		switch (f.op) {
			case BitOr(v), BitAnd(v), BitXor(v), Set(v), Inc(v):
				t.check(f.field, v);
			case Unset:
				t.check(f.field, null);
			case Push(values), Pull(values), AddToSet(values):
				var t = t.resolve(f.field);
				if (!t.isArray())
					f.field.last.pos.error('cannot perform an array operation on '+Context.toComplexType(t.t).toString());
				t.check(new Path([]), values.toArray());
			case Pop(_):
				var t = t.resolve(f.field);
				if (!t.isArray())
					f.field.last.pos.error('cannot perform an array operation on '+Context.toComplexType(t.t).toString());
		}
	}
}
class Update {
	static public function parse(input:Array<Expr>) 
		return Parser.parse(input);
	static public function typeCheck(rep:DocUpdate, t:TypeInfo) {
		//for (f in rep)
			//Typer.type(
		rep.iter(Typer.type.bind(_, t));
		return null;
	}
	static public function generate(rep:DocUpdate):Expr
		return new Generator(rep).gen();
		
}
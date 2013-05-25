package tinx.node.mongo.lang;

using Type;

import haxe.macro.Expr;
import haxe.macro.Type;
import tinx.node.mongo.lang.Path;

using tinx.node.mongo.lang.TypeInfo;
using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
using Lambda;

enum MatchDoc {
	And(s:Array<MatchDoc>);
	Or(s:Array<MatchDoc>);
	Nor(s:Array<MatchDoc>);
	Field(path:Path, s:MatchField);
}

enum MatchField {
	Eq(v:Expr);
	NotEq(v:Expr);
	Gt(v:Expr);
	Gte(v:Expr);
	Lt(v:Expr);
	Lte(v:Expr);
	
	Exists;
	ExistsNot;
	Mod(div:ExprOf<Float>, rem:ExprOf<Float>);
	
	Not(s:MatchField);
	
	All(s:ExprOf<Array<Dynamic>>);
	In(s:ExprOf<Array<Dynamic>>);
	NotIn(s:ExprOf<Array<Dynamic>>);
}

private class MatchTyper {
	static public function check(d:MatchDoc, info:TypeInfo) {
		switch (d) {
			case And(s), Or(s), Nor(s):
				for (d in s) 
					check(d, info);
			case Field(path, s):
				checkField(path, s, info);
		}
	}		
	static var COMPARABLE = [
		'Date' => true,
		'tinx.node.mongo.ObjectID' => true,
	];
	static function checkField(path:Path, s:MatchField, info:TypeInfo) {
		var e = info.resolve(path).blank(path.last.pos);
		switch (s) {
			case Eq(v), NotEq(v), Gt(v), Gte(v), Lt(v), Lte(v):
				var op = if (COMPARABLE.get(e.typeof().sure().getID())) OpEq else OpLt;
				op.make(e, v, v.pos).typeof().sure();
			case Exists, ExistsNot:
				info.check(path, null);
			case Mod(div, rem):
				(macro $e % $div == $rem).finalize(path.last.pos).typeof().sure();
			case Not(s):
				checkField(path, s, info);
			case All(s):
				(macro $e == $s).finalize(s.pos).typeof().sure();
			case In(s), NotIn(s):
				(macro $e == $s[0]).finalize(s.pos).typeof().sure();
		}
	}
}

private class Parser {
	static public function parseDoc(e:Expr):MatchDoc  
		return
			switch (e.expr) {
				case EParenthesis(e): 
					parseDoc(e);
				case EIn(path, { expr: EBinop(OpInterval, e1, e2) } ):
					var path = Path.of(path);
					And([
						Field(path, Gte(e1)),
						Field(path, Lt(e2))
					]);
				case EDisplay(e, _):
					parseDoc(e);
				case EIn(e1, e2):
					Field(Path.of(e1), In(e2));
				case EBinop(OpEq, { expr: EBinop(OpMod, path, div) }, rem):
					Field(Path.of(path), Mod(div, rem));
				case EBinop(OpNotEq, { expr: EBinop(OpMod, path, div) }, rem):
					Field(Path.of(path), Not(Mod(div, rem)));				
				case EUnop(OpNot, false, s):
					negate(parseDoc(s), e.pos);
				case EBinop(op, e1, e2): 
					switch (op) {
						case OpBoolAnd: 
							And([parseDoc(e1), parseDoc(e2)]);
						case OpBoolOr: 
							Or([parseDoc(e1), parseDoc(e2)]);
						case OpEq, OpNotEq, OpLte, OpGte, OpGt, OpLt: 
							Field(
								Path.of(e1),
								MatchField.createEnum(op.enumConstructor().substr(2), [e2])
							);
						default: e.reject('operator $op not allowed');
					}
				default:
					Field(Path.of(e), Exists);
			}			
			
	static public function simplify(s:MatchDoc) 
		return 
			switch (s) {
				case And(s):
					var ret = [];
					for (s in s)
						switch (simplify(s)) {
							case And(s): ret = ret.concat(s);
							case other: ret.push(other);
						}
					And(ret);
				case Or(s):
					var ret = [];
					for (s in s)
						switch (simplify(s)) {
							case Or(s): ret = ret.concat(s);
							case other: ret.push(other);
						}
					Or(ret);
				default: s;
			}	
			
	static function negate(d:MatchDoc, pos:Position) 
		return
			switch (d) {
				case And(s): 
					Or(s.map(negate.bind(_, pos)).array());
				case Or(s): Nor(s);
				case Nor(s): Or(s);
				case Field(name, s): 
					var nu = 
						switch (s) {
							case Exists: ExistsNot;
							case ExistsNot: Exists;
							case In(s): NotIn(s);
							case NotIn(s): In(s);
							case s: Not(s); 
						}
					Field(name, nu);
			}	
}

private class Generate {
	static var map = {
		NotEq: 'ne',
		ExistNot: 'exists',
		NotIn: 'nin'
	}
	static function getMatch(e:EnumValue, v:Expr) {
		var s = e.enumConstructor();
		if (Reflect.hasField(map, s)) 
			s = Reflect.field(map, s);
		else
			s = s.toLowerCase();
		return EObjectDecl([ { field: '$' + s, expr: v } ]).at(v.pos);
	}
	static function field(f:MatchField) {
		function make(e) 
			return getMatch(f, e);
		return 
			switch (f) {
				case Eq(v): v;
				case NotEq(v), Gt(v), Gte(v), Lt(v), Lte(v): make(v);
				case Mod(div, rem): make(macro [$div, $rem]);
				
				case Exists: make(macro true);
				case ExistsNot: make(macro false);
				
				case Not(s): make(field(s));
				case All(s), In(s), NotIn(s): make(s);
			}
	}
	static public function doc(d:MatchDoc) {
		function rec(a:Array<MatchDoc>)
			return [for (d in a) doc(d)].toArray();
		function make(e)
			return getMatch(d, e);
		return 
			switch (d) {
				case And(s), Or(s), Nor(s):
					make(rec(s));
				case Field(path, s):
					var pos = path.last.pos;
					ECast(EObjectDecl([ { field: path.join('.'), expr: field(s) } ]).at(pos), null).at(pos);
			}
	}		
	
	static public function empty() 
		return EObjectDecl([]).at();
}

class Match {
	static public function parse(input:Expr):MatchDoc
		return 
			if (input.getIdent().equals('null')) null;
			else Parser.simplify(Parser.parseDoc(input));
	
	static public function typeCheck(rep:MatchDoc, t:TypeInfo):Void {
		if (rep != null)
			MatchTyper.check(rep, t);
		return null;
	}
	static public function generate(rep:MatchDoc):Expr
		return
			if (rep == null) Generate.empty();
			else Generate.doc(rep);		
}
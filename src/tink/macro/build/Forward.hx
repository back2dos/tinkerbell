package tink.macro.build;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import tink.util.FilterUtils;

using tink.macro.tools.MacroTools;
using tink.util.FilterUtils;
using StringTools;
using Lambda;
using tink.util.Outcome;
/**
 * ...
 * @author back2dos
 */

typedef ClassFieldFilter = ClassField->Bool;

class Forward {
	static inline var TAG = ":forward";
	static public function process(_, members:Array<Member>, constructor:Constructor, hasField:String->Bool, addField:Member->Member) {
		new Forward(hasField, addField).processMembers(members);
	}
	var hasField:String->Bool;
	var addField:Member->Member;
	function new(hasField, addField) {
		this.hasField = hasField;
		this.addField = addField;
	}
	function shortForward(name:String, t:Type, pos:Position) {
		var m = new Member();
		m.name = name;
		m.kind = FVar(t.toComplex());
		m.isPublic = true;
		m.pos = pos;
		addField(m);
	}	
	function processMembers(members:Array<Member>) {
		for (member in members)
			
			switch (member.extractMeta(TAG)) {
				case Success(tag):
					switch (member.kind) {
						case FVar(t, _):
							forwardTo(member, t, tag.pos, tag.params);
						case FProp(_, _, t, _):
							forwardTo(member, t, tag.pos, tag.params);
						case FFun(f):
							
					}
				default:
			}		
		
	}
	function forwardTo(to:Member, t:ComplexType, pos:Position, params:Array<Expr>) {
		var fields = 
			switch (Context.follow(t.toType(pos).data())) {
				case TMono(t): throw 'NI';
				case TInst(t, _): t.get().fields.get();
				case TAnonymous(a): a.get().fields;
				default: pos.error('cannot forward to ' + t);
			}
		var target = ['this', to.name].drill(pos),
			included = makeFilter(params);
			
		for (field in fields) 
			if (field.isPublic && included(field) && !hasField(field.name)) {
				#if display
					shortForward(field.name, field.type, pos);
				#else
					switch (field.kind) {
						case FVar(read, write):
							forwardVarTo(target, field.name, field.type.toComplex(), read, write);
						case FMethod(_):
							switch (Context.follow(field.type)) {
								case TFun(args, ret):
									forwardFunctionTo(target, field.name, args, ret, field.params);
								default: 
									trace(field.type);
									pos.error('wtf?');
							}
					}
				#end
			}
	}
	#if !display
		function forwardFunctionTo(target:Expr, name:String, args:Array<{ name : String, opt : Bool, t : Type }>, ret : Type, params: Array<{ name : String, t : Type }>) {
			var methodArgs = [],
				callArgs = [],
				pos = target.pos;
				
			for (arg in args) {
				callArgs.push(arg.name.resolve(target.pos));
				methodArgs.push( { name : arg.name, opt : arg.opt, type : null, value : null } );
			}
			var methodParams = [];
			for (param in params) 
				methodParams.push( { name : param.name, constraints : [] } );
			addField(Member.method(name, target.field(name, pos).call(callArgs, pos).func(methodArgs, methodParams)));
		}
		function isAccessible(a:VarAccess, read:Bool) {
			return switch(a) {
				case AccNormal, AccCall(_): true;
				case AccInline: read;
				default: false;
			}
		}
		function forwardVarTo(target:Expr, name:String, t:ComplexType, read:VarAccess, write:VarAccess) {
			if (!isAccessible(read, true)) 
				target.pos.error('cannot forward to non-readable field ' + name + ' of ' + t);

			addField(Member.prop(name, t, target.pos, !isAccessible(write, false)));
			addField(Member.method('get_' + name, target.field(name, target.pos).func()));
			if (isAccessible(write, false))
				addField(Member.method('set_' + name, target.field(name).assign('param'.resolve(), target.pos).func([ { name:'param', opt:false, type:t, value:null } ], t)));
		}
	#end
	static function makeFilter(exprs:Array<Expr>) {
		return
			if (exprs.length == 0) 
				function (_) return true;
			else
				exprs.map(makeFieldFilter).one();
	}
	static function matchRegEx(r:String, opt:String):ClassFieldFilter {
		var r = new EReg(r, opt);
		return function (field) return r.match(field.name);
	}
	static function makeFieldFilter(e:Expr):ClassFieldFilter {
		return
			switch (e.expr) {
				case EArrayDecl(exprs): exprs.map(makeFieldFilter).one();
				case EConst(c): 
					switch (c) {
						case CIdent(s), CType(s):
							if (s.startsWith('$')) 
								switch (s.substr(1)) {
									case 'var': function (field:ClassField) return field.isVar();
									case 'function': function (field:ClassField) return !field.isVar();
									default: e.reject('invalid option');
								}
							else 
								function (field) return field.name == s;
						case CString(s): 
							matchRegEx('^' + StringTools.replace(s, '*', '.*') + '$', 'i');
						case CRegexp(r, opt): 
							matchRegEx(r, opt);
						default: e.reject('invalid constant');
					}
				case EBinop(op, e1, e2):
					switch (op) {
						case OpAnd, OpBoolAnd: makeFieldFilter(e1).and(makeFieldFilter(e2)); 
						case OpOr, OpBoolOr: makeFieldFilter(e1).or(makeFieldFilter(e2));
						default: e.reject('invalid operator');
					}
				case EUnop(op, postfix, arg): 
					if (postfix || op != OpNot) e.reject();
					makeFieldFilter(e).not();
				case EParenthesis(e): 
					makeFieldFilter(e);
				default: e.reject();
			}
	}	
}
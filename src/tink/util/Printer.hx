package tink.util;
import haxe.macro.Expr;

/**
 * ...
 * @author back2dos
 */
using Lambda;
class Printer {
	var buf:StringBuf;
	var inc:String;
	public function new(?inc = '  ') {
		this.inc = inc;
	}
	public function print(value:Dynamic) {
		this.buf = new StringBuf();
		this.printRec(value, '');
		return buf.toString();
	}
	inline function nl() {
		buf.add('\n');
	}
	inline function indent(spacer) {
		nl();
		buf.add(spacer);
	}
	function printObject(value, spacer:String) {
		buf.add('{');
		var empty = true;
		{
			var spacer = spacer + inc;
			var first = true;
			for (field in Reflect.fields(value)) {
				if (first) first = false;
				else buf.add(',');
				indent(spacer);
				buf.add(field);
				buf.add(' : ');
				printRec(Reflect.field(value, field), spacer);
				empty = false;
			}
		}
		if (!empty) indent(spacer);
		buf.add('}');
	}
	function printArray(values:Array<Dynamic>, spacer:String) {
		{
			var spacer = spacer + inc;
			var first = true;
			for (value in values) {
				if (first) first = false;
				else buf.add(',');
				indent(spacer);
				printRec(value, spacer);
			}
		}
		if (values.length > 0) indent(spacer);
	}
	function printRec(value:Dynamic, spacer:String) {
		switch (Type.typeof(value)) {
			case TNull: 
				buf.add('null');
			case TInt, TFloat, TBool:
				buf.add(Std.string(value));
			case TFunction: 
				buf.add('#function');
			case TObject:
				printObject(value, spacer);
			case TClass(c):
				if (c == String) {
					buf.add('"');
					buf.add(value);
					buf.add('"');
				}
				else if (c == Array) {
					var a:Array<Dynamic> = value;
					buf.add('[');
					printArray(a, spacer);
					buf.add(']');
				}
				else {//not considering all the other possibilities here (Hash, IntHash, List, Bytes and god knows what)
					printObject(value, spacer);
				}
			case TEnum(_):
				buf.add(Type.enumConstructor(value));
				var a = Type.enumParameters(value);
				if (a.length > 0) {
					buf.add('(');
					printArray(a, spacer);
					buf.add(')');
				}
			case TUnknown:
				#if macro
					var s = Std.string(value);
					if (StringTools.startsWith(s, '#pos(')) {
						var pos = haxe.macro.Context.getPosInfos(value);
						buf.add('haxe.macro.Context.makePosition({ min: ' + pos.min + ', max: ' + pos.max + ', file: "' + pos.file + '" })');
					}
					else
				#end
				buf.add('#unknown');
		}
	}
}
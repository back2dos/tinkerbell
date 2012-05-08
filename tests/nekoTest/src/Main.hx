package ;
import haxe.io.Bytes;
import haxe.io.StringInput;
import tink.io.Unserializer;
import tink.io.Serializer;

class Main {
	static function main() {
		var out = new TestOutput();
		var s = new Serializer(out);
		//s.len(0x400);
		//s.string('hello world');
		//trace(out);
		//var p = 'président';
		var h = 'président';
		//s.string(p);
		//trace(out);
		//s.binary(Bytes.ofString(p));
		//trace(out);
		s.string(h);
		var u = new Unserializer(new StringInput(out.toString()));
		trace(u.string());
		s.binary(Bytes.ofString(h));
		var u = new Unserializer(new StringInput(out.toString()));
		trace(u.binary());
	}
}
import haxe.io.Output;
class TestOutput extends Output {
	var buf:StringBuf;
	public function new() {
		buf = new StringBuf();
	}
	override public function writeByte(c:Int):Void {
		buf.addChar(c);
	}
	public function toString() {
		var ret = buf.toString();
		buf = new StringBuf();
		return ret;
	}
}
package tink.util;
import haxe.macro.Expr;
import tink.macro.tools.AST;
using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
/**
 * ...
 * @author back2dos
 */

interface ChunkIterable<T> {
	function ChunkIter():ChunkIterator<T>;
}
interface ChunkIterator<T> implements ChunkIterable<T> {
	function next(buf:ChunkIterBuffer<T>, count:Int, offset:Int):Int;
}
typedef ChunkIterBuffer<T> = Array<T>;

class ChunkIter {
	@:macro static public function loop<A>(target:ExprRequire<ChunkIterable<A>>, body:Expr, ?id:Expr, ?buf:ExprRequire<Int>) {
		id = id.ifNull('i'.resolve());
		buf = buf.ifNull(100.toExpr());
		return AST.build( {
			var offset = 0,
				tmpTarget = $target,
				tmpSize = $buf,
				tmpBuf = [];
			while (tmpTarget.next(tmpBuf, tmpSize, offset) > 0) {
				offset += tmpSize;
				for ($id in tmpBuf) $body;
			}
		});		
	}
}
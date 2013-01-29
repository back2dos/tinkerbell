package tinx.node.io;

import tink.lang.Cls;

class Stream implements Cls {
	@:forward inline var output:OutStream = _;
	@:forward inline var input:InStream = _;
}
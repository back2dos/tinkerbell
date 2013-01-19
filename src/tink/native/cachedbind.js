try {
	var __fid = 1;
	$bind = function (o, m) {
		m = o.__fid || (o.__fid = __fid++);
		if (o.__hx_closures == null) o.__hx_closures = { };
		if (o.__hx_closures[m] == null) {
		var f = o[m];
			o.__hx_closures[m] = function () {
				return f.apply(o, arguments);
			}
		}
		return o.__hx_closures[m];
	}
	Reflect.compareMethods = function (a, b) { return a == b; }
}
catch (all) {}
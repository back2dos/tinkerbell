try {
	var __fid = 1;
	$bind = function (o, m) {
		var id = m.__fid || (m.__fid = __fid++);
		if (o.__hx_closures == null) o.__hx_closures = { };
		if (o.__hx_closures[id] == null) {
			o.__hx_closures[id] = function () {
				return m.apply(o, arguments);
			}
		}
		return o.__hx_closures[id];
	}
	Reflect.compareMethods = function (a, b) { return a == b; }
}
catch (all) {}
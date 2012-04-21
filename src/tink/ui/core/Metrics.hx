package tink.ui.core;

import tink.collections.maps.ObjectMap;
import tink.lang.Cls;

/**
 * ...
 * @author back2dos
 */
class Metrics {
	var min:Pair<Float>;
	var align:Pair<Float>;
	var weight:Pair<Float>;
	var setPos:Bool->Float->Dynamic;
	var setDim:Bool->Float->Dynamic;
	
	public function new(min, align, weight, setPos, setDim) {
		this.min = min;
		this.align = align;
		this.weight = weight;
		
		this.setPos = setPos;
		this.setDim = setDim;
	}
	public function getMin(h:Bool):Float {
		return min.get(h);
	}
	public function getWeight(h:Bool):Float {
		return weight.get(h);
	}
	public function getAlign(h:Bool):Float {
		return align.get(h);
	}
	
	public function updatePos(h:Bool, pos:Float):Void {
		setPos(h, pos);
	}
	public function updateDim(h:Bool, dim:Float):Void {
		setDim(h, dim);
	}
}

using tink.ui.core.Metrics.MetricsTools;

class MetricsTools {
	static public inline function min(group:Iterable<Metrics>, long:Bool, h:Bool, spacing:Float) {
		return 
			if (long) minLong(group, h, spacing);
			else minShort(group, h);
	}
	static public inline function minShort(group:Iterable<Metrics>, h:Bool) {
		var ret = .0;
		for (m in group)
			ret = Math.max(ret, m.getMin(h));
		return ret;
	}
	static public inline function minLong(group:Iterable<Metrics>, h:Bool, spacing:Float) {
		var ret = -spacing;
		for (m in group)
			ret += m.getMin(h) + spacing;
		return ret;		
	}
	static public inline function arrange(group:Iterable<Metrics>, h, long, offset, total, spacing) {
		if (long)
			arrangeLong(group, h, offset, total, spacing);
		else
			arrangeShort(group, h, offset, total);
	}
	static public function arrangeShort(group:Iterable<Metrics>, h:Bool, offset:Float, total:Float) {
		var maxWeight = Math.NEGATIVE_INFINITY,
			weight = .0;
			
		for (m in group) 
			maxWeight = Math.max(maxWeight, m.getWeight(h));
			
		for (m in group) {
			var weight = m.getWeight(h);
			var dim = 
				if (weight == .0) 
					m.getMin(h)
				else
					Math.max(m.getMin(h), total * weight / maxWeight);
				
			m.updateDim(h, dim);
			m.updatePos(h, (total - dim) * m.getAlign(h) + offset);
		}
	}
	static public function arrangeLong(group:Iterable<Metrics>, h:Bool, offset:Float, total:Float, spacing:Float) {

		var totalWeight = .0,
			infos = [],
			sizes = new ObjectMap(),
			weight = .0;
		function setSize(m:Metrics, size:Float) {
			m.updateDim(h, size);
			sizes.set(m, size);
			total -= size;
		}		
		
		for (m in group) {
			total -= spacing;
			weight = m.getWeight(h);
			if (weight == .0)
				setSize(m, m.getMin(h));
			else {
				totalWeight += weight;
				infos.push(new RelSizeInfo(m.getMin(h), weight, m));				
			}				
		}
		total += spacing;	
		infos.sort(function (i1, i2) 
			return (i1.min / i1.weight > i2.min / i2.weight) ? -1 : 1
		);
		
		for (i in infos) {
			setSize(i.owner, Math.max(i.min, total * i.weight / totalWeight));
			totalWeight -= i.weight;
		}
		var pos = offset;
		for (m in group) {
			m.updatePos(h, pos);
			pos += sizes.get(m) + spacing;
		}
	}
}
private class RelSizeInfo {
	public var min(default, null):Float;
	public var weight(default, null):Float;
	public var owner(default, null):Metrics;
	public function new(min, weight, owner) {
		this.min = min;
		this.weight = weight;
		this.owner = owner;
	}
}
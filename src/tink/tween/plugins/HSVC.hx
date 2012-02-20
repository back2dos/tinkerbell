package tink.tween.plugins;

/**
 * ...
 * @author back2dos
 */

import flash.display.DisplayObject;
import flash.filters.BitmapFilter;
import flash.filters.ColorMatrixFilter;
import flash.utils.TypedDictionary;
import tink.devtools.Debug;
import tink.lang.Cls;
import tink.tween.Tween;
import tink.tween.Tweener;

import tink.tween.plugins.PluginBase;

class Hue extends PluginBase<DisplayObject> {
	var matrix:ColorMatrixHelper;
	override function init(end:Float):Float {
		Debug.log(end);
		this.matrix = ColorMatrixHelper.get(this.target);
		return Smart.angle(this.matrix.hue, end);
	}
	override function setValue(v:Float):Null<TweenCallback> {
		this.matrix.hue = v;
		return this.matrix.update;
	}
	override function cleanup() {
		this.matrix.release();
		this.matrix = null;
		return null;
	}
}
class Brightness extends PluginBase<DisplayObject> {
	var matrix:ColorMatrixHelper;
	override function init(end:Float):Float {
		this.matrix = ColorMatrixHelper.get(this.target);
		return this.matrix.brightness;
	}
	override function setValue(v:Float):Null<TweenCallback> {
		this.matrix.brightness = v;
		return this.matrix.update;
	}
	override function cleanup() {
		this.matrix.release();
		this.matrix = null;
		return null;
	}
}
class Saturation extends PluginBase<DisplayObject> {
	var matrix:ColorMatrixHelper;
	override function init(end:Float):Float {
		this.matrix = ColorMatrixHelper.get(this.target);
		return this.matrix.saturation;
	}
	override function setValue(v:Float):Null<TweenCallback> {
		this.matrix.saturation = v;
		return this.matrix.update;
	}
	override function cleanup() {
		this.matrix.release();
		this.matrix = null;
		return null;
	}
}
class Contrast extends PluginBase<DisplayObject> {
	var matrix:ColorMatrixHelper;
	override function init(end:Float):Float {
		this.matrix = ColorMatrixHelper.get(this.target);
		return this.matrix.contrast;
	}
	override function setValue(v:Float):Null<TweenCallback> {
		this.matrix.contrast = v;
		return this.matrix.update;
	}
	override function cleanup() {
		this.matrix.release();
		this.matrix = null;
		return null;
	}
}

private class ColorMatrixHelper implements Cls {
	
	var target:DisplayObject;
	var count:Int;
	var archiveCount:Int;
	var valid:Bool = true;
	
	@:prop(invalidate(param)) var hue:Float;
	@:prop(invalidate(param)) var brightness:Float;
	@:prop(invalidate(param)) var contrast:Float;
	@:prop(invalidate(param)) var saturation:Float;
	
	function new(target) {
		this.target = target;
		this.count = 1;
		this.hue = 0;
		this.brightness = 0;
		this.saturation = 0;
		this.contrast = 0;
		var filter = getFilter(target.filters);
		///This part here reflects my lack of knowledge in linear algebra. I know no better.
		if (filter != null) {
			var key = Std.string(filter.matrix);
			var other = archive.get(key);
			if (other != null) {
				this.hue = other.hue;
				this.brightness = other.brightness;
				this.contrast = other.contrast;
				this.saturation = other.saturation;
				
				if (--other.archiveCount < 1)
					archive.remove(key);//be gone! this time for real!
			}
		}
	}
	inline function invalidate(param) {
		this.valid = false;
		return param;
	}
	function getFilter(filters:Array<Dynamic>):ColorMatrixFilter {
		for (f in filters)
			if (Std.is(f, ColorMatrixFilter)) 
				return f;
		return null;
	}
	public function update() {
		if (!valid && count > 0) {
			var filters = target.filters;
			var filter = getFilter(filters);
			if (filter == null)
				filters.unshift(filter = new ColorMatrixFilter());
				
			filter.matrix = calcMatrix();
			target.filters = filters;
		}
	}
	function calcMatrix() {
		var ret = new ColorMatrix();
		if (hue != 0) ret.adjustHue(hue);
		if (contrast != 0) ret.adjustContrast(contrast);
		if (brightness != 0) ret.adjustBrightness(brightness);
		if (saturation != 0) ret.adjustSaturation(saturation);
		return ret.toArray();
	}
	static var archive = new Hash<ColorMatrixHelper>();
	public function release() {
		if (--count == 0) {
			map.delete(target);
			var key = Std.string(getFilter(target.filters).matrix);
			if (archive.exists(key)) //occurs when two targets have been tweened to the same parameters
				archive.get(key).archiveCount ++;
			else {
				this.archiveCount = 1;
				archive.set(key, this);
			}
			this.target = null;
		}
	}
	static public function get(target:DisplayObject) {
		var ret = map.get(target);
		if (ret == null)
			map.set(target, ret = new ColorMatrixHelper(target));
		else
			ret.count++;
		return ret;
	}
	static var map = new TypedDictionary();
}

//All code below this line has been taken from gtweenhx as is, except for the removal of the package stament and making the class declaration private

/**                                                               *                                                               *
* Initial haXe port by Brett Johnson, http://now.periscopic.com   *
* Project site: code.google.com/p/gtweenhx/                       *
* . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . *
*
* ColorMatrix by Grant Skinner. August 8, 2005
* Updated to AS3 November 19, 2007
* Visit www.gskinner.com/blog for documentation, updates and more free code.
*
*
* Copyright (c) 2009 Grant Skinner
* 
* Permission is hereby granted, free of charge, to any person
* obtaining a copy of this software and associated documentation
* files (the "Software"), to deal in the Software without
* restriction, including without limitation the rights to use,
* copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the
* Software is furnished to do so, subject to the following
* conditions:
* 
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
* OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
* HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
* OTHER DEALINGS IN THE SOFTWARE.
**/


private class ColorMatrix{ //cannot extend Array in haXe
		
	// constant for contrast calculations:
		private inline static var DELTA_INDEX:Array<Float> = [
			0,    0.01, 0.02, 0.04, 0.05, 0.06, 0.07, 0.08, 0.1,  0.11,
			0.12, 0.14, 0.15, 0.16, 0.17, 0.18, 0.20, 0.21, 0.22, 0.24,
			0.25, 0.27, 0.28, 0.30, 0.32, 0.34, 0.36, 0.38, 0.40, 0.42,
			0.44, 0.46, 0.48, 0.5,  0.53, 0.56, 0.59, 0.62, 0.65, 0.68, 
			0.71, 0.74, 0.77, 0.80, 0.83, 0.86, 0.89, 0.92, 0.95, 0.98,
			1.0,  1.06, 1.12, 1.18, 1.24, 1.30, 1.36, 1.42, 1.48, 1.54,
			1.60, 1.66, 1.72, 1.78, 1.84, 1.90, 1.96, 2.0,  2.12, 2.25, 
			2.37, 2.50, 2.62, 2.75, 2.87, 3.0,  3.2,  3.4,  3.6,  3.8,
			4.0,  4.3,  4.7,  4.9,  5.0,  5.5,  6.0,  6.5,  6.8,  7.0,
			7.3,  7.5,  7.8,  8.0,  8.4,  8.7,  9.0,  9.4,  9.6,  9.8, 
			10.0
		];
	
		// identity matrix constant:
		private inline static var IDENTITY_MATRIX:Array<Float> = [
			1.0,0,0,0,0,
			0,1,0,0,0,
			0,0,1,0,0,
			0,0,0,1,0,
			0,0,0,0,1
		];
		private inline static var LENGTH:Float = 25;//IDENTITY_MATRIX.length;
	
	
	
	
	public var myMatrix:Array<Float>;//cannot extend Array in haxe, include as property
	
	
	// initialization:
		public function new(?matrix : Array<Float> = null) {
			myMatrix = fixMatrix(matrix);//matrix = fixMatrix(matrix);
			copyMatrix(((myMatrix.length == LENGTH) ? myMatrix : IDENTITY_MATRIX));//copyMatrix(((matrix.length == LENGTH) ? matrix : IDENTITY_MATRIX));
		}
		
	// public methods:
		public function reset():Void {
			for(i in 0...LENGTH){//for (var i:uint=0; i<LENGTH; i++) {
				//this[i] = IDENTITY_MATRIX[i];
				myMatrix[i] = IDENTITY_MATRIX[i];
			}
		}
	
		public function adjustColor(brightness:Float,contrast:Float,saturation:Float,hue:Float):Void {
			adjustHue(hue);
			adjustContrast(contrast);
			adjustBrightness(brightness);
			adjustSaturation(saturation);
		}

		public function adjustBrightness(value:Float):Void {
			value = cleanValue(value,255);
			if (value == 0 || Math.isNaN(value)) { return; }
				multiplyMatrix([
				1,0,0,0,value,
				0,1,0,0,value,
				0,0,1,0,value,
				0,0,0,1,0,
				0,0,0,0,1
			]);
		}
	
		public function adjustContrast(value:Float):Void {
			value = cleanValue(value,100);
			if (value == 0 || Math.isNaN(value)) { return; }
			var x:Float;
			if (value<0) {
				x = 127+value/100*127;
			} else {
				x = value-Math.floor(value);//value%1;
				if (x == 0) {
					x = DELTA_INDEX[Math.floor(value)];//DELTA_INDEX[value];
				} else {
					//x = DELTA_INDEX[(value<<0)]; // this is how the IDE does it.
					//x = DELTA_INDEX[(value<<0)]*(1-x)+DELTA_INDEX[(value<<0)+1]*x; // use linear interpolation for more granularity.
					x = DELTA_INDEX[Math.floor(value)]*(1-x)+DELTA_INDEX[Math.floor(value)+1]*x; // use linear interpolation for more granularity.
				}
				x = x*127+127;
			}
			multiplyMatrix([
				x/127,0,0,0,0.5*(127-x),
				0,x/127,0,0,0.5*(127-x),
				0,0,x/127,0,0.5*(127-x),
				0,0,0,1,0,
				0,0,0,0,1
			]);
		}
	
		public function adjustSaturation(value:Float):Void {
			value = cleanValue(value,100);
			if (value == 0 || Math.isNaN(value)) { return; }
			var x:Float = 1+((value > 0) ? 3*value/100 : value/100);
			var lumR:Float = 0.3086;
			var lumG:Float = 0.6094;
			var lumB:Float = 0.0820;
			multiplyMatrix([
				lumR*(1-x)+x,lumG*(1-x),lumB*(1-x),0,0,
				lumR*(1-x),lumG*(1-x)+x,lumB*(1-x),0,0,
				lumR*(1-x),lumG*(1-x),lumB*(1-x)+x,0,0,
				0,0,0,1,0,
				0,0,0,0,1
			]);
		}
	
		public function adjustHue(value:Float):Void {
			value = cleanValue(value,180)/180*Math.PI;
			if (value == 0 || Math.isNaN(value)) { return; }
			var cosVal:Float = Math.cos(value);
			var sinVal:Float = Math.sin(value);
			var lumR:Float = 0.213;
			var lumG:Float = 0.715;
			var lumB:Float = 0.072;
			multiplyMatrix([
				lumR+cosVal*(1-lumR)+sinVal*(-lumR),lumG+cosVal*(-lumG)+sinVal*(-lumG),lumB+cosVal*(-lumB)+sinVal*(1-lumB),0,0,
				lumR+cosVal*(-lumR)+sinVal*(0.143),lumG+cosVal*(1-lumG)+sinVal*(0.140),lumB+cosVal*(-lumB)+sinVal*(-0.283),0,0,
				lumR+cosVal*(-lumR)+sinVal*(-(1-lumR)),lumG+cosVal*(-lumG)+sinVal*(lumG),lumB+cosVal*(1-lumB)+sinVal*(lumB),0,0,
				0,0,0,1,0,
				0,0,0,0,1
			]);
		}
	
		public function concat(matrix:Array<Float>):Void {
			matrix = fixMatrix(matrix);
			if (matrix.length != LENGTH) { return; }
			multiplyMatrix(matrix);
		}
		
		public function clone():ColorMatrix {
			return new ColorMatrix(this.myMatrix);
		}
	
		public function toString():String {
			//return "ColorMatrix [ "+this.join(" , ")+" ]";
			return "ColorMatrix [ "+myMatrix.join(" , ")+" ]";
		}
		
		// return a length 20 array (5x4):
		public function toArray():Array<Float> {
			//return slice(0,20);
			return myMatrix.slice(0,20);
		}
	
	// private methods:
		// copy the specified matrix's values to this matrix:
		private function copyMatrix(matrix:Array<Float>):Void {
			//var l:Float = LENGTH;
			for(i in 0...LENGTH){//for (var i:uint=0;i<l;i++) {
				//this[i] = matrix[i];
				myMatrix[i] = matrix[i];
			}
		}
	
		// multiplies one matrix against another:
		private function multiplyMatrix(matrix:Array<Float>):Void {
			var col:Array<Float> = [];
			
			for(i in 0...5){//for (var i:uint=0;i<5;i++) {
				for(j in 0...5){//for (var j:uint=0;j<5;j++) {
					col[j] = myMatrix[j+i*5];//this[j+i*5];
				}
				for(j in 0...5){//for (j=0;j<5;j++) {
					var val:Float=0;
					for(k in 0...5){//for (var k:Number=0;k<5;k++) {
						val += matrix[j+k*5]*col[k];
					}
					myMatrix[j+i*5] = val;//this[j+i*5] = val;
				}
			}
		}
		
		// make sure values are within the specified range, hue has a limit of 180, others are 100:
		private function cleanValue(value:Float,limit:Float):Float {
			return Math.min(limit,Math.max(-limit,value));
		}
	
		// makes sure matrixes are 5x5 (25 long):
		private function fixMatrix(?matrix:Array<Float>=null):Array<Float> {
			if (matrix == null) { return IDENTITY_MATRIX; }
			if (Std.is(matrix,ColorMatrix)) { matrix = matrix.slice(0); }
			if (matrix.length < LENGTH) {
				matrix = matrix.slice(0,matrix.length).concat(IDENTITY_MATRIX.slice(matrix.length,LENGTH));
			} else if (matrix.length > LENGTH) {
				matrix = matrix.slice(0,LENGTH);
			}
			return matrix;
		}
}
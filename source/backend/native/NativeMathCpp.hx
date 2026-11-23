package backend.native;

#if cpp
import cpp.Float32;
import cpp.RawPointer;

/**
 * Thin hxcpp binding. Keep this API flat: pointers, counts and scalar values only.
 * C++ never owns or keeps a Haxe object after the call returns.
 */
extern class NativeMathCpp
{
	@:native('plus_native_api_version')
	public static function apiVersion():Int;

	@:native('plus_wave_batch')
	public static function waveBatch(input:RawPointer<Float32>, output:RawPointer<Float32>, count:Int,
		time:Float, frequency:Float, amplitude:Float):Void;
}
#end

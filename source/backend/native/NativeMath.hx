package backend.native;

import lime.utils.Float32Array;

#if cpp
import cpp.Float32;
import cpp.Pointer as CppPointer;
import cpp.RawPointer;
import cpp.UInt8;
#end

/** Batched math shared by the native backend and its portable Haxe fallback. */
#if cpp
@:cppFileCode('
#include <cstddef>
extern "C" int plus_native_api_version();
extern "C" void plus_wave_batch(const float* input, float* output, std::size_t count,
	double time, double frequency, double amplitude);
')
#end
@:build(backend.native.NativeBuild.configure())
class NativeMath
{
	public static function apiVersion():Int
	{
		#if cpp
		return NativeMathCpp.apiVersion();
		#else
		return 0;
		#end
	}

	/**
	 * Applies a wave to every input value. Input and output may be reused between
	 * frames; the C++ path reads/writes their existing contiguous memory.
	 */
	public static function waveBatch(input:Float32Array, output:Float32Array, time:Float,
		frequency:Float, amplitude:Float):Void
	{
		var count:Int = checkedCount(input, output);
		#if cpp
		NativeMathCpp.waveBatch(floatPointer(input), floatPointer(output), count,
			time, frequency, amplitude);
		#else
		waveBatchHaxe(input, output, time, frequency, amplitude);
		#end
	}

	/** Reference implementation used by unsupported targets and parity tests. */
	public static function waveBatchHaxe(input:Float32Array, output:Float32Array, time:Float,
		frequency:Float, amplitude:Float):Void
	{
		var count:Int = checkedCount(input, output);
		for (i in 0...count)
		{
			var value:Float = input[i];
			output[i] = value + Math.sin((value + time) * frequency) * amplitude;
		}
	}

	static inline function checkedCount(input:Float32Array, output:Float32Array):Int
	{
		if (input == null || output == null)
			throw 'NativeMath.waveBatch requires non-null buffers';
		if (output.length < input.length)
			throw 'NativeMath.waveBatch output is too small (${output.length} < ${input.length})';
		return input.length;
	}

	#if cpp
	static inline function floatPointer(values:Float32Array):RawPointer<Float32>
	{
		var bytes = values.toBytes();
		var pointer:CppPointer<UInt8> = CppPointer.arrayElem(bytes.getData(), values.byteOffset);
		return cast pointer.ptr;
	}
	#end
}

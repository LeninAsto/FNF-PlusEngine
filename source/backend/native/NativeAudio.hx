package backend.native;

import haxe.io.Bytes;
import lime.utils.Float32Array;

#if cpp
import cpp.Float32;
import cpp.Pointer as CppPointer;
import cpp.RawPointer;
import cpp.UInt8;
#end

/** Allocation-free analysis kernels for decoded PCM owned by Lime/Haxe. */
#if cpp
@:cppFileCode('
#include <cstddef>
#include <cstdint>
extern "C" int plus_waveform_peaks(const std::uint8_t* pcm, std::size_t byte_length,
	int channels, int start_frame, int end_frame, int max_rows, float multiply, float* output);
')
#end
class NativeAudio
{
	public static inline final OUTPUT_STRIDE:Int = 4;

	/** Returns written rows: left min/max followed by right min/max. PCM is signed 16-bit LE. */
	public static function waveformPeaks(pcm:Bytes, channels:Int, startFrame:Int, endFrame:Int,
		maxRows:Int, multiply:Float, output:Float32Array):Int
	{
		check(pcm, channels, maxRows, output);
		#if cpp
		return NativeAudioCpp.waveformPeaks(bytePointer(pcm), pcm.length, channels,
			startFrame, endFrame, maxRows, multiply, floatPointer(output));
		#else
		return waveformPeaksHaxe(pcm, channels, startFrame, endFrame, maxRows, multiply, output);
		#end
	}

	public static function waveformPeaksHaxe(pcm:Bytes, channels:Int, startFrame:Int, endFrame:Int,
		maxRows:Int, multiply:Float, output:Float32Array):Int
	{
		check(pcm, channels, maxRows, output);
		var bytesPerFrame = channels * 2;
		var frameCount = Std.int(pcm.length / bytesPerFrame);
		var frame = Std.int(Math.max(0, startFrame));
		endFrame = Std.int(Math.min(frameCount, endFrame));
		if (frame >= endFrame)
			return 0;

		var framesPerRow = Std.int(Math.max(1, Std.int((endFrame - frame) / maxRows)));
		var lmin = 0.0;
		var lmax = 0.0;
		var rmin = 0.0;
		var rmax = 0.0;
		var rows = 0;
		while (frame < endFrame)
		{
			var offset = frame * bytesPerFrame;
			var left = sample16(pcm, offset);
			lmin = Math.min(lmin, left);
			lmax = Math.max(lmax, left);
			var right = channels >= 2 ? sample16(pcm, offset + 2) : left;
			rmin = Math.min(rmin, right);
			rmax = Math.max(rmax, right);
			if (frame % framesPerRow == 0)
			{
				var out = rows * OUTPUT_STRIDE;
				output[out] = Math.abs(lmin) * multiply;
				output[out + 1] = lmax * multiply;
				output[out + 2] = Math.abs(rmin) * multiply;
				output[out + 3] = rmax * multiply;
				lmin = lmax = rmin = rmax = 0;
				rows++;
				if (rows > maxRows)
					break;
			}
			frame++;
		}
		return rows;
	}

	static inline function sample16(pcm:Bytes, offset:Int):Float
	{
		var value = pcm.getUInt16(offset);
		if (value > 32767) value -= 65536;
		return value / 32768;
	}

	static inline function check(pcm:Bytes, channels:Int, maxRows:Int, output:Float32Array):Void
	{
		if (pcm == null || output == null || channels <= 0 || maxRows <= 0)
			throw 'NativeAudio.waveformPeaks received invalid arguments';
		if (output.length < (maxRows + 1) * OUTPUT_STRIDE)
			throw 'NativeAudio.waveformPeaks output is too small';
	}

	#if cpp
	static inline function bytePointer(values:Bytes):RawPointer<UInt8>
		return cast CppPointer.arrayElem(values.getData(), 0).ptr;

	static inline function floatPointer(values:Float32Array):RawPointer<Float32>
	{
		var bytes = values.toBytes();
		var pointer:CppPointer<UInt8> = CppPointer.arrayElem(bytes.getData(), values.byteOffset);
		return cast pointer.ptr;
	}
	#end
}

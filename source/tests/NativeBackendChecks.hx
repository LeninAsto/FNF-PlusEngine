package tests;

import backend.native.NativeBackend;
import backend.native.NativeAudio;
import backend.native.NativeGeometry;
import backend.native.NativeMath;
import backend.native.NativeNotes;
import haxe.Timer;
import haxe.io.Bytes;
import lime.utils.Float32Array;
import openfl.Vector;

/** Run a test-enabled build with --native-backend-self-test. */
#if (cpp && windows)
@:cppFileCode('#include <windows.h>')
#elseif cpp
@:cppFileCode('#include <cstdlib>')
#end
class NativeBackendChecks
{
	static final LENGTH:Int = 65536;
	static final ITERATIONS:Int = 120;
	public static var report(default, null):String = '';

	public static function run():Void
	{
		NativeBackend.init();
		if (!NativeBackend.available || NativeBackend.apiVersion != 4 || !NativeBackend.notesAvailable)
			throw 'native backend unavailable or incompatible (API ${NativeBackend.apiVersion})';

		var input = new Float32Array(LENGTH);
		var expected = new Float32Array(LENGTH);
		var actual = new Float32Array(LENGTH);
		for (i in 0...LENGTH)
			input[i] = (i - LENGTH * 0.5) * 0.03125;

		NativeMath.waveBatchHaxe(input, expected, 1.25, 0.017, 48.0);
		NativeMath.waveBatch(input, actual, 1.25, 0.017, 48.0);

		var maxError:Float = 0;
		for (i in 0...LENGTH)
		{
			var error = Math.abs(expected[i] - actual[i]);
			if (error > maxError)
				maxError = error;
		}
		if (maxError > 0.0001)
			throw 'wave parity failed; max error $maxError';

		var geometryReport = checkGeometry();
		var audioReport = checkAudio();
		var notesReport = checkNotes();

		// Warm both paths before timing so startup/JIT-like cache effects stay out.
		for (_ in 0...4)
		{
			NativeMath.waveBatchHaxe(input, expected, 2.0, 0.013, 32.0);
			NativeMath.waveBatch(input, actual, 2.0, 0.013, 32.0);
		}

		var start = Timer.stamp();
		for (i in 0...ITERATIONS)
			NativeMath.waveBatchHaxe(input, expected, i * 0.01, 0.013, 32.0);
		var haxeMs = (Timer.stamp() - start) * 1000;

		start = Timer.stamp();
		for (i in 0...ITERATIONS)
			NativeMath.waveBatch(input, actual, i * 0.01, 0.013, 32.0);
		var nativeMs = (Timer.stamp() - start) * 1000;

		report = '\nAPI: ${NativeBackend.apiVersion}'
			+ '\nValues: $LENGTH x $ITERATIONS iterations'
			+ '\nMax error: $maxError'
			+ '\nHaxe: ${roundMs(haxeMs)} ms'
			+ '\nC++: ${roundMs(nativeMs)} ms'
			+ '\nRatio (Haxe/C++): ${roundMs(haxeMs / nativeMs)}x'
			+ geometryReport
			+ audioReport;
		report += notesReport;
	}

	static function checkNotes():String
	{
		var report = '';
		var empty = new Vector<Float>(0, true);
		NativeNotes.timingWindows(empty, empty, empty, Bytes.alloc(0), Bytes.alloc(0), 0, 166.67);
		for (count in [8, 32, 128, 1024, 8192])
		{
			var times = new Vector<Float>(count, true);
			var late = new Vector<Float>(count, true);
			var early = new Vector<Float>(count, true);
			var states = Bytes.alloc(count);
			var expected = Bytes.alloc(count);
			var actual = Bytes.alloc(count);
			var routed = Bytes.alloc(count);
			for (i in 0...count)
			{
				times[i] = 100000 + (i - count * 0.5) * 3.75;
				late[i] = 0.65 + (i % 5) * 0.17;
				early[i] = 0.75 + (i % 7) * 0.11;
				var state = (i % 13 == 0) ? NativeNotes.STATE_WAS_GOOD_HIT : 0;
				if (i % 97 == 0) state |= NativeNotes.STATE_ALREADY_TOO_LATE;
				states.set(i, state);
			}

			NativeNotes.timingWindowsHaxe(times, late, early, states, expected, count, 100000, 166.67);
			NativeNotes.timingWindowsNative(times, late, early, states, actual, count, 100000, 166.67);
			NativeNotes.timingWindows(times, late, early, states, routed, 100000, 166.67);
			for (i in 0...count)
			{
				if (expected.get(i) != actual.get(i))
					throw 'note timing native parity failed at count $count, index $i (${expected.get(i)} != ${actual.get(i)})';
				if (expected.get(i) != routed.get(i))
					throw 'note timing routed parity failed at count $count, index $i (${expected.get(i)} != ${routed.get(i)})';
			}

			var iterations = Std.int(Math.max(500, 2000000 / count));
			var start = Timer.stamp();
			for (i in 0...iterations)
				NativeNotes.timingWindowsHaxe(times, late, early, states, expected, count, 100000 + i * 0.01, 166.67);
			var haxeMs = (Timer.stamp() - start) * 1000;
			start = Timer.stamp();
			for (i in 0...iterations)
				NativeNotes.timingWindowsNative(times, late, early, states, actual, count, 100000 + i * 0.01, 166.67);
			var nativeMs = (Timer.stamp() - start) * 1000;
			report += '\nNote windows $count x $iterations: Haxe ${roundMs(haxeMs)} ms, '
				+ 'C++ ${roundMs(nativeMs)} ms, ${roundMs(haxeMs / nativeMs)}x';
		}
		return report;
	}

	static function checkGeometry():String
	{
		var report = '';
		for (vertexCount in [4, 16, 32, 128, 384])
		{
			var baseline = makeVertices(vertexCount);
			var actual = makeVertices(vertexCount);
			NativeGeometry.affine2DHaxe(baseline, vertexCount, 0.91, 0.13, -0.27, 1.07, 48.5, -17.25);
			NativeGeometry.affine2DNative(actual, vertexCount, 0.91, 0.13, -0.27, 1.07, 48.5, -17.25);
			var maxError = 0.0;
			for (i in 0...baseline.length)
				maxError = Math.max(maxError, Math.abs(baseline[i] - actual[i]));
			if (maxError > 0.0000001)
				throw 'geometry parity failed at $vertexCount vertices; max error $maxError';

			var iterations = Std.int(Math.max(2000, 1200000 / vertexCount));
			var haxeData = makeVertices(vertexCount);
			var nativeData = makeVertices(vertexCount);
			var start = Timer.stamp();
			for (_ in 0...iterations)
				NativeGeometry.affine2DHaxe(haxeData, vertexCount, 1, 0, 0, 1, 0.01, -0.01);
			var haxeMs = (Timer.stamp() - start) * 1000;
			start = Timer.stamp();
			for (_ in 0...iterations)
				NativeGeometry.affine2DNative(nativeData, vertexCount, 1, 0, 0, 1, 0.01, -0.01);
			var nativeMs = (Timer.stamp() - start) * 1000;
			report += '\nAffine $vertexCount vertices: Haxe ${roundMs(haxeMs)} ms, C++ ${roundMs(nativeMs)} ms, ${roundMs(haxeMs / nativeMs)}x';
		}
		return report;
	}

	static function checkAudio():String
	{
		var frames:Int = 441000;
		var channels:Int = 2;
		var pcm:Bytes = Bytes.alloc(frames * channels * 2);
		for (frame in 0...frames)
		{
			var left:Int = (frame * 97 % 65536) - 32768;
			var right:Int = (frame * 193 % 65536) - 32768;
			var offset:Int = frame * 4;
			pcm.set(offset, left & 0xff);
			pcm.set(offset + 1, (left >> 8) & 0xff);
			pcm.set(offset + 2, right & 0xff);
			pcm.set(offset + 3, (right >> 8) & 0xff);
		}

		var maxRows:Int = 4096;
		var expected = new Float32Array((maxRows + 1) * NativeAudio.OUTPUT_STRIDE);
		var actual = new Float32Array((maxRows + 1) * NativeAudio.OUTPUT_STRIDE);
		var expectedRows = NativeAudio.waveformPeaksHaxe(pcm, channels, 137, frames - 83, maxRows, 0.83, expected);
		var actualRows = NativeAudio.waveformPeaks(pcm, channels, 137, frames - 83, maxRows, 0.83, actual);
		if (expectedRows != actualRows)
			throw 'waveform row parity failed ($expectedRows != $actualRows)';
		var maxError = 0.0;
		for (i in 0...(actualRows * NativeAudio.OUTPUT_STRIDE))
			maxError = Math.max(maxError, Math.abs(expected[i] - actual[i]));
		if (maxError > 0.000001)
			throw 'waveform value parity failed; max error $maxError';

		var iterations:Int = 30;
		var start = Timer.stamp();
		for (_ in 0...iterations)
			NativeAudio.waveformPeaksHaxe(pcm, channels, 137, frames - 83, maxRows, 0.83, expected);
		var haxeMs = (Timer.stamp() - start) * 1000;
		start = Timer.stamp();
		for (_ in 0...iterations)
			NativeAudio.waveformPeaks(pcm, channels, 137, frames - 83, maxRows, 0.83, actual);
		var nativeMs = (Timer.stamp() - start) * 1000;

		return '\nWaveform ${frames} frames x $iterations: Haxe ${roundMs(haxeMs)} ms, '
			+ 'C++ ${roundMs(nativeMs)} ms, ${roundMs(haxeMs / nativeMs)}x, max error $maxError';
	}

	static function makeVertices(vertexCount:Int):Vector<Float>
	{
		var result = new Vector<Float>(vertexCount * 2, true);
		for (i in 0...result.length)
			result[i] = (i % 31) * 0.75 - 8;
		return result;
	}

	/** Hard exit is intentional: this command runs before Lime starts its event loop. */
	public static function exitProcess(code:Int):Void
	{
		#if (cpp && windows)
		untyped __cpp__('::TerminateProcess(::GetCurrentProcess(), {0})', code);
		#elseif cpp
		untyped __cpp__('std::_Exit({0})', code);
		#else
		Sys.exit(code);
		#end
	}

	static inline function roundMs(value:Float):Float
		return Math.round(value * 1000) / 1000;
}

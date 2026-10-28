package backend.native;

import haxe.io.Bytes;
import openfl.Vector;

#if cpp
import cpp.Float64;
import cpp.Pointer as CppPointer;
import cpp.RawPointer;
import cpp.UInt8;
#end

/**
 * Batched timing kernels for player notes. Haxe still owns Note objects and
 * gameplay decisions; this class only evaluates numeric timing windows.
 */
#if cpp
@:cppFileCode('
#include <cstddef>
#include <cstdint>
extern "C" void plus_note_windows_batch(const double* strum_times, const double* late_hit_mults,
	const double* early_hit_mults, const std::uint8_t* states, std::uint8_t* output,
	std::size_t count, double song_position, double safe_zone_offset);
')
#end
class NativeNotes
{
	public static inline final STATE_WAS_GOOD_HIT:Int = 1;
	public static inline final STATE_ALREADY_TOO_LATE:Int = 2;
	public static inline final OUTPUT_CAN_BE_HIT:Int = 1;
	public static inline final OUTPUT_TOO_LATE:Int = 2;
	/** Conservative crossover chosen from the release self-test benchmark. */
	public static inline final MIN_NATIVE_NOTES:Int = 32;

	public static function timingWindows(strumTimes:Vector<Float>, lateHitMults:Vector<Float>,
		earlyHitMults:Vector<Float>, states:Bytes, output:Bytes,
		songPosition:Float, safeZoneOffset:Float):Void
	{
		var count = checkedCount(strumTimes, lateHitMults, earlyHitMults, states, output);
		#if cpp
		if (count >= MIN_NATIVE_NOTES && vectorArray(strumTimes) != null
			&& vectorArray(lateHitMults) != null && vectorArray(earlyHitMults) != null)
		{
			timingWindowsNative(strumTimes, lateHitMults, earlyHitMults, states, output,
				count, songPosition, safeZoneOffset);
			return;
		}
		#end
		timingWindowsHaxe(strumTimes, lateHitMults, earlyHitMults, states, output,
			count, songPosition, safeZoneOffset);
	}

	public static function timingWindowsHaxe(strumTimes:Vector<Float>, lateHitMults:Vector<Float>,
		earlyHitMults:Vector<Float>, states:Bytes, output:Bytes, count:Int,
		songPosition:Float, safeZoneOffset:Float):Void
	{
		count = checkedExplicitCount(strumTimes, lateHitMults, earlyHitMults, states, output, count);
		var lateLimit = songPosition - safeZoneOffset;
		for (i in 0...count)
		{
			var time = strumTimes[i];
			var result = 0;
			if (time > songPosition - safeZoneOffset * lateHitMults[i]
				&& time < songPosition + safeZoneOffset * earlyHitMults[i])
				result |= OUTPUT_CAN_BE_HIT;
			var state = states.get(i);
			if ((state & STATE_ALREADY_TOO_LATE) != 0
				|| (time < lateLimit && (state & STATE_WAS_GOOD_HIT) == 0))
				result |= OUTPUT_TOO_LATE;
			output.set(i, result);
		}
	}

	public static function timingWindowsNative(strumTimes:Vector<Float>, lateHitMults:Vector<Float>,
		earlyHitMults:Vector<Float>, states:Bytes, output:Bytes, count:Int,
		songPosition:Float, safeZoneOffset:Float):Void
	{
		count = checkedExplicitCount(strumTimes, lateHitMults, earlyHitMults, states, output, count);
		if (count == 0)
			return;
		#if cpp
		var times = vectorArray(strumTimes);
		var late = vectorArray(lateHitMults);
		var early = vectorArray(earlyHitMults);
		if (times == null || late == null || early == null)
		{
			timingWindowsHaxe(strumTimes, lateHitMults, earlyHitMults, states, output,
				count, songPosition, safeZoneOffset);
			return;
		}
		NativeNotesCpp.timingWindows(doublePointer(times), doublePointer(late), doublePointer(early),
			bytePointer(states), bytePointer(output), count, songPosition, safeZoneOffset);
		#else
		timingWindowsHaxe(strumTimes, lateHitMults, earlyHitMults, states, output,
			count, songPosition, safeZoneOffset);
		#end
	}

	static inline function checkedCount(strumTimes:Vector<Float>, lateHitMults:Vector<Float>,
		earlyHitMults:Vector<Float>, states:Bytes, output:Bytes):Int
		return checkedExplicitCount(strumTimes, lateHitMults, earlyHitMults, states, output,
			strumTimes == null ? 0 : strumTimes.length);

	static function checkedExplicitCount(strumTimes:Vector<Float>, lateHitMults:Vector<Float>,
		earlyHitMults:Vector<Float>, states:Bytes, output:Bytes, count:Int):Int
	{
		if (strumTimes == null || lateHitMults == null || earlyHitMults == null || states == null || output == null)
			throw 'NativeNotes.timingWindows requires non-null buffers';
		if (count < 0 || strumTimes.length < count || lateHitMults.length < count
			|| earlyHitMults.length < count || states.length < count || output.length < count)
			throw 'NativeNotes.timingWindows buffer is smaller than count ($count)';
		return count;
	}

	#if cpp
	@:privateAccess
	static inline function vectorArray(values:Vector<Float>):Array<Float>
	{
		var storage:Dynamic = cast values;
		return cast storage.__array;
	}

	static inline function doublePointer(values:Array<Float>):RawPointer<Float64>
		return cast CppPointer.ofArray(values).ptr;

	static inline function bytePointer(values:Bytes):RawPointer<UInt8>
		return cast CppPointer.arrayElem(values.getData(), 0).ptr;
	#end
}

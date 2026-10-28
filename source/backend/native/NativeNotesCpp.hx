package backend.native;

#if cpp
import cpp.Float64;
import cpp.RawPointer;
import cpp.UInt8;

/** Flat hxcpp binding for batched note timing. C++ retains no pointers. */
extern class NativeNotesCpp
{
	@:native('plus_note_windows_batch')
	public static function timingWindows(strumTimes:RawPointer<Float64>, lateHitMults:RawPointer<Float64>,
		earlyHitMults:RawPointer<Float64>, states:RawPointer<UInt8>, output:RawPointer<UInt8>,
		count:Int, songPosition:Float, safeZoneOffset:Float):Void;
}
#end

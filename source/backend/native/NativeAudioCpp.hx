package backend.native;

#if cpp
import cpp.Float32;
import cpp.RawPointer;
import cpp.UInt8;

/** Flat hxcpp binding for read-only PCM analysis. */
extern class NativeAudioCpp
{
	@:native('plus_waveform_peaks')
	public static function waveformPeaks(pcm:RawPointer<UInt8>, byteLength:Int, channels:Int,
		startFrame:Int, endFrame:Int, maxRows:Int, multiply:Float, output:RawPointer<Float32>):Int;
}
#end

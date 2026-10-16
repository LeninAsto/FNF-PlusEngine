package backend;

import flixel.sound.FlxSound;

/** Bridges FlxSound to Lime's native pitch-independent tempo control. */
class AudioTempo
{
	public static function apply(sound:FlxSound, rate:Float, preservePitch:Bool):Void
	{
		if (sound == null) return;
		var canPreservePitch:Bool = false;

		#if (lime && lime_vorbis && !html5 && !flash)
		@:privateAccess
		if (sound._channel != null && sound._channel.__audioSource != null && sound._channel.__audioSource.buffer != null)
			canPreservePitch = sound._channel.__audioSource.buffer.__srcVorbisFile != null;
		#end
		var useTempo:Bool = preservePitch && canPreservePitch;

		#if FLX_PITCH
		// Tempo stretching only works with Lime's streamed Vorbis source. Keep
		// decoded/mobile audio synchronized by falling back to normal pitch speed.
		sound.pitch = useTempo ? 1 : rate;
		#end

		#if (lime && !html5 && !flash)
		@:privateAccess
		if (sound._channel != null && sound._channel.__audioSource != null)
			sound._channel.__audioSource.tempo = useTempo ? rate : 1;
		#end
	}
}

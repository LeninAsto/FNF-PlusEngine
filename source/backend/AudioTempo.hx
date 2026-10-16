package backend;

import flixel.sound.FlxSound;

/** Bridges FlxSound to Lime's native pitch-independent tempo control. */
class AudioTempo
{
	// Lime's streamed Signalsmith path becomes unstable in this engine build
	// when a song repeatedly restarts above 2x. Fall back to regular pitch
	// playback outside the range that is known to be stable.
	public static inline var MAX_STABLE_TEMPO:Float = 2.0;
	static var warnedAboutTempoLimit:Bool = false;

	public static function apply(sound:FlxSound, rate:Float, preservePitch:Bool):Void
	{
		if (sound == null)
			return;

		var safeRate:Float = Math.isFinite(rate) && rate > 0 ? rate : 1;
		var canPreservePitch:Bool = false;

		#if (lime && lime_vorbis && !html5 && !flash)
		@:privateAccess
		if (sound._channel != null && sound._channel.__audioSource != null && sound._channel.__audioSource.buffer != null)
			canPreservePitch = sound._channel.__audioSource.buffer.__srcVorbisFile != null;
		#end
		var useTempo:Bool = preservePitch && canPreservePitch && safeRate <= MAX_STABLE_TEMPO;
		if (preservePitch && canPreservePitch && safeRate > MAX_STABLE_TEMPO && !warnedAboutTempoLimit)
		{
			warnedAboutTempoLimit = true;
			trace('Preserve Pitch: $safeRate' + 'x exceeds the stable 2x tempo limit; using normal pitch playback.');
		}

		// Clear an earlier tempo stretch before switching back to pitch playback.
		// Doing this first also prevents pitch and tempo from being multiplied
		// briefly while a looping song changes rate.
		#if (lime && !html5 && !flash)
		@:privateAccess
		if (!useTempo && sound._channel != null && sound._channel.__audioSource != null)
			sound._channel.__audioSource.tempo = 1;
		#end

		#if FLX_PITCH
		// Tempo stretching only works with Lime's streamed Vorbis source. Keep
		// decoded/mobile audio synchronized by falling back to normal pitch speed.
		sound.pitch = useTempo ? 1 : safeRate;
		#end

		#if (lime && !html5 && !flash)
		@:privateAccess
		if (useTempo && sound._channel != null && sound._channel.__audioSource != null)
			sound._channel.__audioSource.tempo = safeRate;
		#end
	}
}

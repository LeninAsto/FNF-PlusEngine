package states.play;

import objects.Note;
import objects.NoteSplash;
import objects.StrumNote;
import objects.SustainSplash;
import states.PlayState;

class NoteSplashHelper
{
	public static function warmup(state:PlayState):Void
	{
		if (state == null)
			return;

		var splash:NoteSplash = new NoteSplash();
		state.grpNoteSplashes.add(splash);
		splash.alpha = 0.000001; // Invisible sprites may skip the atlas warmup.

		if (!ClientPrefs.data.hideSustainSplash && !ClientPrefs.data.lowQuality)
		{
			SustainSplash.startCrochet = Conductor.stepCrochet;
			SustainSplash.frameRate = Math.floor(24 / 100 * saneBpm(PlayState.SONG != null ? PlayState.SONG.bpm : Conductor.bpm));
			var sus = new SustainSplash();
			sus.alpha = 0.000001;
			state.grpHoldSplashes.add(sus);
		}
	}

	public static function spawnOnNote(state:PlayState, note:Note):Void
	{
		if (state == null || note == null)
			return;

		var strum:StrumNote = state.playerStrums.members[note.noteData];
		if (strum != null)
			spawn(state, strum.x, strum.y, note.noteData, note, strum);
	}

	public static function spawn(state:PlayState, x:Float = 0, y:Float = 0, ?data:Int = 0, ?note:Note, ?strum:StrumNote):Void
	{
		if (state == null)
			return;

		var splash:NoteSplash = state.grpNoteSplashes.recycle(NoteSplash);
		splash.babyArrow = strum;
		splash.spawnSplashNote(x, y, data, note);
		state.grpNoteSplashes.add(splash);
	}

	static inline function saneBpm(value:Float):Float
		return (Math.isNaN(value) || value <= 0) ? 100 : value;
}

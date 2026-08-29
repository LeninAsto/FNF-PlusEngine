package;

import backend.Mods;
import backend.Highscore;
import backend.Language;
import lime.app.Application;
import flixel.FlxG;
import backend.CoolUtil;
import states.FlashingState;
import states.TitleState;

/**
 * InitialState - Decides which state to start with.
 * Loads mods first, then goes to the default TitleState.
 */
class InitialState extends MusicBeatState
{
	override function create()
	{
		#if HSCRIPT_ALLOWED
		backend.CustomFadeTransition.initCustomTransitionScript();
		#end

		super.create();

		Highscore.load();
		Language.reloadPhrases();

		// Apply preferences-dependent runtime settings.
		#if !html5
		FlxG.autoPause = ClientPrefs.data.autoPause;
		#end

		MusicBeatState.switchState(new TitleState());
	}
}


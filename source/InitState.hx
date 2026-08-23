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
 * Loads mods first, then checks if the top mod has custom state scripts
 * and loads them; otherwise goes to the default TitleState.
 */
class InitialState extends MusicBeatState
{
	override function create()
	{
		// Initialize GlobalScript before anything else
		// This is the first state created, so FlxG.state now exists
		#if HSCRIPT_ALLOWED
		backend.MusicBeatState.initGlobalScript();
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


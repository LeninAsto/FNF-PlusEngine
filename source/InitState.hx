package;

#if (HSCRIPT_ALLOWED && MODS_ALLOWED && !mobile)
import backend.ScriptableState;
import psychlua.CustomState;
#end
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

		// ScriptableState.tryCreate checks mods then engine assets automatically.
		// CustomState is kept as a fallback for old flat-callback scripts.
		#if (HSCRIPT_ALLOWED && MODS_ALLOWED && !mobile)
		if (ScriptableState.overridesEnabled()) {
			var shouldAskFlashing = FlxG.save.data != null && FlxG.save.data.flashing == null && !FlashingState.leftState;
			if (shouldAskFlashing) {
				var flashingScript = ScriptableState.tryCreate('FlashingState', new FlashingState());
				if (flashingScript != null) {
					MusicBeatState.switchState(flashingScript);
					return;
				} else if (CustomState.hasScript('FlashingState')) {
					MusicBeatState.switchState(new CustomState('FlashingState'));
					return;
				}
			}

			var titleScript = ScriptableState.tryCreate('TitleState', new TitleState());
			if (titleScript != null) {
				MusicBeatState.switchState(titleScript);
				return;
			} else if (CustomState.hasScript('TitleState')) {
				MusicBeatState.switchState(new CustomState('TitleState'));
				return;
			}
		}
		#end

		// No mod states found, use default TitleState
		MusicBeatState.switchState(new TitleState());
	}
}

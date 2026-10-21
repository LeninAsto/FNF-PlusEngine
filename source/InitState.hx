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

		ClientPrefs.loadPrefs();
		Highscore.load();
		Language.reloadPhrases();
		MobileData.init();

		#if DENSE_CHART_TEST
		Mods.currentModDirectory = 'NewFall Tracks with chart';
		Mods.pushGlobalMods();
		states.PlayState.SONG = backend.Song.loadFromJson('floccinaucinihilipilificatiophobia-part6', 'floccinaucinihilipilificatiophobia');
		states.PlayState.isStoryMode = false;
		states.PlayState.startOnTime = 170500;
		states.LoadingState.prepareToSong();
		states.LoadingState.loadAndSwitchState(new states.PlayState());
		return;
		#end

		// Apply preferences-dependent runtime settings.
		#if !html5
		FlxG.autoPause = ClientPrefs.data.autoPause;
		#end

		#if HSCRIPT_ALLOWED
		trace("scripted?");
		if ((Mods.launchedMod == null || Mods.launchedMod.length < 1) && FlxG.save.data.launchedMod != null)
			Mods.launchedMod = Std.string(FlxG.save.data.launchedMod);

		trace("Mod Launched: " + Mods.launchedMod);
		if (Mods.launchedMod != null && Mods.launchedMod.length > 0 && Mods.isLaunchable(Mods.launchedMod))
		{
			Mods.currentModDirectory = Mods.launchedMod;
			Mods.pushGlobalMods();
			Mods.applyWindowBrand(Mods.launchedMod);
			Language.reloadPhrases();
			scripting.GlobalScriptManager.loadForMod(Mods.launchedMod);
			var entry:String = Mods.getEntryState(Mods.launchedMod);
			var scripted:MusicBeatState = scripting.ScriptedStates.loadState(entry, [], scripting.ScriptedStates.ResolveScope.LAUNCHED);
			if (scripted != null)
			{
				MusicBeatState.switchState(scripted);
				return;
			}
			trace("Scriptable = null!");
		}
		else if (Mods.launchedMod != null && Mods.launchedMod.length > 0)
		{
			FlxG.save.data.launchedMod = null;
			FlxG.save.flush();
			Mods.launchedMod = null;
			Mods.currentModDirectory = '';
			Mods.pushGlobalMods();
			Mods.resetWindowBrand();
		}
		MusicBeatState.switchState(new TitleState());
		#else
		trace("meh, hardcoded");
		MusicBeatState.switchState(new TitleState());
		#end
	}
}


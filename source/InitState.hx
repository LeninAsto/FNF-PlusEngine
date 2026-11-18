package;

import backend.Mods;
import backend.Highscore;
import backend.Language;
import lime.app.Application;
import flixel.FlxG;
import backend.CoolUtil;
import states.FlashingState;
import states.TitleState;
import backend.native.NativeBackend;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

/**
 * InitialState - Decides which state to start with.
 * Loads mods first, then goes to the default TitleState.
 */
class InitialState extends MusicBeatState
{
	var startupFill:FlxSprite;
	var startupLabel:FlxText;
	var startupStep:Int = 0;
	static inline final STARTUP_STEPS:Int = 3;

	override function create()
	{
		super.create();
		createStartupScreen();
		// Let OpenFL present this first frame before work such as preferences,
		// language files and enabled mods begins on the main thread.
		new FlxTimer().start(0.01, function(_) loadStartupRuntime());
	}

	function createStartupScreen():Void
	{
		var background = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF151022);
		add(background);

		var panelWidth:Int = Std.int(Math.min(640, FlxG.width - 64));
		var panelX:Float = (FlxG.width - panelWidth) * 0.5;
		var panelY:Float = FlxG.height * 0.58;
		var title = new FlxText(panelX, panelY - 58, panelWidth, 'PLUS ENGINE', 28);
		title.setFormat(Paths.font('vcr.ttf'), 28, FlxColor.WHITE, CENTER);
		add(title);

		startupLabel = new FlxText(panelX, panelY - 22, panelWidth, '', 16);
		startupLabel.setFormat(Paths.font('vcr.ttf'), 16, 0xFFD9D2F0, CENTER);
		add(startupLabel);

		var barBack = new FlxSprite(panelX, panelY + 12).makeGraphic(panelWidth, 16, 0xFF34284B);
		add(barBack);
		startupFill = new FlxSprite(panelX + 2, panelY + 14).makeGraphic(panelWidth - 4, 12, 0xFF8F55DF);
		startupFill.origin.set(0, 0);
		add(startupFill);
		setStartupProgress('Preparing engine...', 0);
	}

	function setStartupProgress(label:String, step:Int):Void
	{
		startupStep = step;
		if (startupLabel != null)
			startupLabel.text = label;
		if (startupFill != null)
		{
			startupFill.scale.x = Math.max(0.015, startupStep / STARTUP_STEPS);
			startupFill.updateHitbox();
		}
	}

	function loadStartupRuntime():Void
	{
		setStartupProgress('Loading preferences and language...', 1);
		#if HSCRIPT_ALLOWED
		backend.CustomFadeTransition.initCustomTransitionScript();
		#end
		NativeBackend.init();

		ClientPrefs.loadPrefs();
		Highscore.load();
		Language.reloadPhrases();
		MobileData.init();
		#if (debug && sys)
		if (Sys.args().indexOf('--modchart-self-test') != -1)
		{
			try { tests.ModchartEditorChecks.run(); sys.io.File.saveContent('modchart-checks.txt', 'PASS: chart plans, 21001 dense notes, Lua/scene roundtrips, negative beats, localization, instruction limit, Manager forward/backward seek.' + tests.ModchartEditorChecks.report); Sys.exit(0); }
			catch (error:Dynamic) { sys.io.File.saveContent('modchart-checks.txt', 'FAIL at ' + tests.ModchartEditorChecks.report + ': ' + error + '\n' + haxe.CallStack.toString(haxe.CallStack.exceptionStack())); Sys.exit(1); }
			return;
		}
		if (Sys.args().indexOf('--modchart-editor') != -1)
		{
			MusicBeatState.switchState(new states.editors.ModchartEditorState());
			return;
		}
		#end
		new FlxTimer().start(0.01, function(_) resolveStartupDestination());
	}

	function resolveStartupDestination():Void
	{
		setStartupProgress('Loading enabled mods...', 2);

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
			Mods.loadTopMod();
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
			scripting.ScriptedStates.clearLaunchedModContext();
		}
		else if (Mods.launchedMod != null && Mods.launchedMod.length > 0)
		{
			scripting.ScriptedStates.clearLaunchedModContext();
		}
		else
			Mods.loadTopMod();
		setStartupProgress('Starting game...', 3);
		MusicBeatState.switchState(new TitleState());
		#else
		trace("meh, hardcoded");
		Mods.loadTopMod();
		setStartupProgress('Starting game...', 3);
		MusicBeatState.switchState(new TitleState());
		#end
	}
}


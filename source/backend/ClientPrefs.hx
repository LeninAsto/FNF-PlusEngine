package backend;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
//import funkin.cloud.GoogleCloudSyncNotifier;

import states.TitleState;

// Add a variable here and it will get automatically saved
@:structInit class SaveVariables {
	// Mobile and Mobile Controls Releated
	public var extraButtons:String = "NONE"; // mobile extra button option
	public var hitboxPos:Bool = true; // hitbox extra button position option
	public var dynamicColors:Bool = true; // yes cause its cool -Karim
	public var controlsAlpha:Float = FlxG.onMobile ? 0.6 : 0;
	public var showTouchPointer:Bool = true; // show touch pointer indicator (like Android dev option)
	public var showMobileDebugButtons:Bool = false; // show T and D debug buttons on mobile
	public var screensaver:Bool = false;
	public var infinityDisplay:Bool = false; // Extend viewport vertically for modern screens while keeping game at 16:9
	#if android
	public var storageType:String = "EXTERNAL_DATA";
	public var androidOptimizationsApplied:Bool = false; // One-time optimization flag
	public var androidOptimizationProfileVersion:Int = 0;
	#end
	public var hitboxType:String = "Gradient";
	public var popUpRating:Bool = true;
	public var versionTextOnGameplay:Bool = false;
	public var gameOverVibration:Bool = false;
	public var fpsRework:Bool = true;
	public var mobileReceptorAlign:Bool = false; // Align receptors with hitbox lanes (mobile only, may break scripts)
	#if windows
	public var fullscreenMode:String = 'Borderless'; // 'Borderless', 'Borderless Fix', 'Exclusive'
	#end
	public var accuracySystem:String = 'Wife3'; // 'Wife3', 'Psych', 'Simple', 'osu!mania', 'DJMAX', 'ITG'
	public var badShitBreakCombo:Bool = false; // When true, Bad and Shit will break the combo
	public var systemScoreMultiplier:String = 'Psych'; // 'Psych', 'Codename'
	public var downScroll:Bool = false;
	public var middleScroll:Bool = false;
	public var opponentStrums:Bool = true;
	public var showFPS:Bool = true;
	public var vsync:Bool = false;
	public var fpsDebugLevel:Int = 0; // FPSCounter debug level (persistent)
	public var showWatermark:Bool = false;
	public var flashing:Bool = true;
	public var autoPause:Bool = true;
	public var antialiasing:Bool = true;
	#if windows
	public var changeWindowBorderColorWithNoteHit:Bool = false; // Changes window border color on note hit (Windows 11 only)
	#end
	public var noteSkin:String = 'Default';
	public var noteRGB:Bool = true;
	public var splashSkin:String = 'Psych';
	public var splashAlpha:Float = 0.6;
	public var colorQuantization:Bool = false; // StepMania-style color quantization
	public var menuAccentColor:String = 'Purple';
	public var menuDarkTheme:Bool = false;
	public var lowQuality:Bool = false;
	public var shaders:Bool = true;
	public var colorblindMode:String = 'None';
	public var cacheOnGPU:Bool = #if !switch false #else true #end; // GPU Caching made by Raltyro
	public var framerate:Int = 60;
	public var camZooms:Bool = true;
	public var hideHud:Bool = false;
	public var hideSustainSplash:Bool = true;
	public var showKeyViewer:Bool = false;
	public var iconBounceType:String = 'Default';
	public var judgementCounter:Bool = false;
	public var showRating:Bool = true;
	public var showCombo:Bool = true;
	public var showComboNum:Bool = true;
	public var comboInGame:Bool = false;
	public var useFreakyFont:Bool = false;
	public var showStateInFPS:Bool = true;
	public var showEndCountdown:Bool = false; // Enables/disables the end countdown
	public var endCountdownSeconds:Int = 10;  // End countdown seconds (10-30)
	public var camera3dEnabled:Bool = true; // Enables 3D camera transformations
	public var zScale:Float = 1.0; // Z-axis depth scale (0.1-5.0)
	public var renderArrowPaths:Bool = false; // Renders arrow trajectory lines (performance intensive)
	public var styledArrowPaths:Bool = false; // Applies colors/transparency to arrow paths
	public var arrowPathBoundary:Int = 300; // Pixels beyond screen to render paths (0-1000)
	public var optimizeHolds:Bool = false; // Optimizes hold rendering (not recommended for complex modcharts)
	public var holdsBehindStrum:Bool = false; // Renders sustains behind strum line
	public var holdEndScale:Float = 1.0; // Scale multiplier for hold note endings (0.1-3.0)
	public var holdCacheEnabled:Bool = true; // Hold graphics cache for performance
	public var holdAlphaDivisions:Int = 20; // Pre-calculated alpha variants (10-30)
	public var columnSpecificModifiers:Bool = true; // Enables per-lane modifier calculations
	
	public var noteOffset:Int = 0;
	public var arrowRGB:Array<Array<FlxColor>> = [
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038]];
	public var arrowRGBPixel:Array<Array<FlxColor>> = [
		[0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
		[0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
		[0xFF71E300, 0xFFF6FFE6, 0xFF003100],
		[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000]];
	public var arrowHSV:Array<Array<Float>> = [
		[0, 0, 0],
		[0, 0, 0],
		[0, 0, 0],
		[0, 0, 0]
	];

	public var ghostTapping:Bool = true;
	public var timeBarType:String = 'Time Left';
	public var useWavyTimeBar:Bool = false;
	public var shadedTimeBar:Bool = false;
	public var scoreZoom:Bool = true;
	public var timeBump:Bool = false;
	public var noReset:Bool = false;
	public var healthBarAlpha:Float = 1;
	public var smoothHealthBar:Bool = true;
	public var smoothHPBug:Bool = false;
	public var usePsychScoreText:Bool = true;
	public var hitsoundVolume:Float = 0;
	public var hitSounds:String = "None";
	public var hitsoundType:String = "None";
	public var pauseMusic:String = 'Tea Time';
	public var checkForUpdates:Bool = true;
	public var comboStacking:Bool = true;
	public var enablePreloader:Bool = false; // Enable global asset preloader on startup
	public var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative', 
		// anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
		// an amod example would be chartSpeed * multiplier
		// cmod would just be constantSpeed = chartSpeed
		// and xmod basically works by basing the speed on the bpm.
		// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
		// bps is calculated by bpm / 60
		// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
		// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
		// oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
		// -kade
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
		'opponentdrain' => false, // JS Engine-style: opponent note hits drain player health
		'opponentplay' => false,
		'perfect' => false, // Perfect Mode - insta-kill on any judgement below Sick
		'nodroppenalty' => false // Hold drops don't cause misses
	];

	public var comboOffset:Array<Int> = [0, 0, 0, 0];
	public var keyViewerOffset:Array<Int> = [0, 0]; // X, Y offset for key viewer
	public var keyViewerColor:String = 'Gray'; // Color name for key viewer
	public var ratingOffset:Int = 0;
	public var flawlessRating:Bool = true;
	public var flawlessWindow:Float = 20.0;
	public var sickWindow:Float = 45.0;
	public var goodWindow:Float = 90.0;
	public var badWindow:Float = 135.0;
	public var safeFrames:Float = 10.0;
	public var guitarHeroSustains:Bool = false;
	public var discordRPC:Bool = true;
	public var loadingScreen:Bool = true;
	public var language:String = 'en-US';
	public var abbreviateScore:Bool = true;
	public var newfreeplay:Bool = true;
	public var vanillaTransition:Bool = false; // Use vanilla Psych Engine transition instead of custom
	public var cloudProvider:String = 'Google';
	public var cloudSessionStatus:String = 'Not signed in';
	public var firebaseDesktopLoginUrl:String = 'https://fnf-plus-engine.web.app/auth';
	public var firebaseApiKey:String = 'AIzaSyBBuMPZbBMLTic9RFKTR-I0b-wmbdPgR-I';
	public var firebaseProjectId:String = 'fnf-plus-engine';
	public var firebaseRealtimeDbUrl:String = 'https://fnf-plus-engine-default-rtdb.firebaseio.com';
	public var googleCloudUid:String = '';
	public var googleCloudEmail:String = '';
	public var googleFirebaseIdToken:String = '';
	public var googleFirebaseRefreshToken:String = '';
	public var cloudLastLocalSaveAt:String = '';
	public var cloudLastCloudPushAt:String = '';
	public var cloudLastCloudPullAt:String = '';
	public var cloudLastSeenRemoteSnapshotAt:String = '';
	public var cloudLastSeenRemoteSnapshotHash:String = '';
	public var cloudDebugTraces:Bool = true;
	public var gameJoltUsername:String = '';
	public var gameJoltToken:String = '';
	public var gameJoltGameId:String = '';
	public var gameJoltPrivateKey:String = '';
	public var pauseCountdown:Bool = false; // Enable countdown when resuming from pause
	public var heyIntro:Bool = false; // Boyfriend and Girlfriend do Hey! animation on countdown Go!
	public var breakTimer:Bool = false; // Show timer when next notes are approaching
	public var disableLargeChartGC:Bool = false; // Skip manual GC pass for large charts to reduce loading stutters
	public var legacyMemoryManagement:Bool = false; // Use Psych 0.7.3 memory management style (no GPU disposal)
	public var legacyFileSystemAccess:Bool = false; // Allow direct FileSystem.readDirectory access like in Psych 0.7.3
	public var legacyShaderInit:Bool = false; // Use Psych 0.7.3 shader initialization (glslVersion parameter, direct FlxRuntimeShader)
	public var autoConvertChartsToV2:Bool = false; // Automatically convert psych_v1 charts to psych_v2 format when loading
	public var useScriptableCustomStates:Bool = false; // Allow scripted state overrides through ScriptableState and CustomState
}

class ClientPrefs {
	public static var data:SaveVariables = {};
	public static var defaultData:SaveVariables = {};
	public static var judgementCounter:Bool = false;

	//Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		//Key Bind, Name for ControlsSubState
		'note_up'		=> [W, UP],
		'note_left'		=> [A, LEFT],
		'note_down'		=> [S, DOWN],
		'note_right'	=> [D, RIGHT],
		
		'ui_up'			=> [W, UP],
		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_right'		=> [D, RIGHT],
		
		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R],
		
		'volume_mute'	=> [ZERO],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],
		
		'debug_1'		=> [SEVEN],
		'debug_2'		=> [EIGHT],
		'debug_3'		=> [SIX],
		
		'fullscreen'	=> [F11]
	];
	public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
		'note_up'		=> [DPAD_UP, Y],
		'note_left'		=> [DPAD_LEFT, X],
		'note_down'		=> [DPAD_DOWN, A],
		'note_right'	=> [DPAD_RIGHT, B],
		
		'ui_up'			=> [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		'ui_left'		=> [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'ui_down'		=> [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		'ui_right'		=> [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
		
		'accept'		=> [A, START],
		'back'			=> [B],
		'pause'			=> [START],
		'reset'			=> [BACK]
	];
	public static var mobileBinds:Map<String, Array<MobileInputID>> = [
		'note_up'		=> [NOTE_UP],
		'note_left'		=> [NOTE_LEFT],
		'note_down'		=> [NOTE_DOWN],
		'note_right'	=> [NOTE_RIGHT],

		'ui_up'			=> [UP],
		'ui_left'		=> [LEFT],
		'ui_down'		=> [DOWN],
		'ui_right'		=> [RIGHT],

		'accept'		=> [A],
		'back'			=> [B],
		'pause'			=> [#if android NONE #else P #end],
		'reset'			=> [NONE]
	];
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	public static var defaultButtons:Map<String, Array<FlxGamepadInputID>> = null;
	public static var defaultMobileBinds:Map<String, Array<MobileInputID>> = null;
	static var controlsSaveCache:FlxSave = null;

	static function getControlsSave():FlxSave
	{
		if (controlsSaveCache == null)
		{
			controlsSaveCache = new FlxSave();
			controlsSaveCache.bind('controls_v3', CoolUtil.getSavePath());
		}
		return controlsSaveCache;
	}

	public static function resetKeys(controller:Null<Bool> = null) //Null = both, False = Keyboard, True = Controller
	{
		if(controller != true)
			for (key in keyBinds.keys())
				if(defaultKeys.exists(key))
					keyBinds.set(key, defaultKeys.get(key).copy());

		if(controller != false)
			for (button in gamepadBinds.keys())
				if(defaultButtons.exists(button))
					gamepadBinds.set(button, defaultButtons.get(button).copy());
	}

	public static function clearInvalidKeys(key:String)
	{
		var keyBind:Array<FlxKey> = keyBinds.get(key);
		var gamepadBind:Array<FlxGamepadInputID> = gamepadBinds.get(key);
		var mobileBind:Array<MobileInputID> = mobileBinds.get(key);
		while(keyBind != null && keyBind.contains(NONE)) keyBind.remove(NONE);
		while(gamepadBind != null && gamepadBind.contains(NONE)) gamepadBind.remove(NONE);
		while(mobileBind != null && mobileBind.contains(NONE)) mobileBind.remove(NONE);
	}

	public static function loadDefaultKeys()
	{
		defaultKeys = keyBinds.copy();
		defaultButtons = gamepadBinds.copy();
		defaultMobileBinds = mobileBinds.copy();
	}

	#if android
	public static function loadStorageTypeEarly():Void
	{
		var save:FlxSave = new FlxSave();
		save.bind('funkin', CoolUtil.getSavePath());
		if (save != null && save.data != null && Reflect.hasField(save.data, 'storageType'))
		{
			var storedType = Reflect.field(save.data, 'storageType');
			if (storedType != null)
			{
				data.storageType = switch (storedType)
				{
					case 'EXTERNAL': 'EXTERNAL';
					case 'INTERNAL', 'EXTERNAL_DATA': 'INTERNAL';
					default: 'INTERNAL';
				};
			}
		}
	}
	#end

	public static function saveSettings() {
		data.cloudLastLocalSaveAt = Date.now().toString();

		for (key in Reflect.fields(data))
			Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));

		#if ACHIEVEMENTS_ALLOWED Achievements.save(); #end
		FlxG.save.flush();
		#if android
		StorageUtil.saveStorageTypePreference(data.storageType);
		#end

        //Wow counter =p
        Reflect.setField(FlxG.save.data, "judgementCounter", judgementCounter);
		data.judgementCounter = judgementCounter;

		//Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		var save = getControlsSave();
		save.data.keyboard = keyBinds;
		save.data.gamepad = gamepadBinds;
		save.data.mobile = mobileBinds;
		save.flush();
		//GoogleCloudSyncNotifier.notifySaveEvent();
		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs() {
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end

		for (key in Reflect.fields(data))
			if (key != 'gameplaySettings' && Reflect.hasField(FlxG.save.data, key))
				Reflect.setField(data, key, Reflect.field(FlxG.save.data, key));

		// Fixed timestep is now always enabled to keep simulation and interpolation consistent.
		data.fpsRework = true;
		
		if(Main.fpsVar != null)
			Main.fpsVar.visible = data.showFPS;

		#if (!html5 && !switch)
		FlxG.autoPause = ClientPrefs.data.autoPause;

		if(FlxG.save.data.framerate == null) {
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
			data.framerate = Std.int(FlxMath.bound(refreshRate, 60, 240));
		}
		#end

		if (Reflect.hasField(FlxG.save.data, "judgementCounter"))
            judgementCounter = !!Reflect.field(FlxG.save.data, "judgementCounter");
		    judgementCounter = data.judgementCounter;

		applyFramePacing();

		#if (!html5 && !switch)
		try
		{
			if (FlxG.stage != null && FlxG.stage.application != null && FlxG.stage.application.window != null)
				Reflect.setProperty(FlxG.stage.application.window, 'vsync', data.vsync);
		}
		catch (e:Dynamic)
		{
			// Some targets may not expose window vsync.
		}
		#end

		if(FlxG.save.data.gameplaySettings != null)
		{
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
				data.gameplaySettings.set(name, value);
		}
		
		// flixel automatically saves your volume!
		if(FlxG.save.data.volume != null)
			FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.mute != null)
			FlxG.sound.muted = FlxG.save.data.mute;

		#if DISCORD_ALLOWED DiscordClient.check(); #end

		// controls on a separate save file
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', CoolUtil.getSavePath());
		if(save != null)
		{
			if(save.data.keyboard != null)
			{
				var loadedControls:Map<String, Array<FlxKey>> = save.data.keyboard;
				for (control => keys in loadedControls)
					if(keyBinds.exists(control)) keyBinds.set(control, keys);
			}
			if(save.data.gamepad != null)
			{
				var loadedControls:Map<String, Array<FlxGamepadInputID>> = save.data.gamepad;
				for (control => keys in loadedControls)
					if(gamepadBinds.exists(control)) gamepadBinds.set(control, keys);
			}
			if(save.data.mobile != null) {
				var loadedControls:Map<String, Array<MobileInputID>> = save.data.mobile;
				for (control => keys in loadedControls)
					if(mobileBinds.exists(control)) mobileBinds.set(control, keys);
			}
			reloadVolumeKeys();
		}
	}

	public static function applyFramePacing():Void
	{
		// Keep fixed timestep + interpolation always on for stable gameplay timing.
		data.fpsRework = true;
		var safeFramerate:Int = Std.int(Math.max(30, data.framerate));
		var drawFramerate:Int = getInterpolatedDrawFramerate(safeFramerate);

		FlxG.fixedTimestep = true;
		FlxG.updateFramerate = safeFramerate;
		FlxG.drawFramerate = drawFramerate;
		FlxG.maxElapsed = 1 / safeFramerate;

		#if (!html5 && !switch)
		try
		{
			if (FlxG.stage != null)
			{
				FlxG.stage.frameRate = drawFramerate;
				if (FlxG.stage.window != null)
					FlxG.stage.window.frameRate = drawFramerate;
			}
		}
		catch (e:Dynamic)
		{
			// Ignore targets that do not expose window frame rate at runtime.
		}
		#end
	}

	static function getInterpolatedDrawFramerate(safeFramerate:Int):Int
	{
		#if (!html5 && !switch)
		try
		{
			if (FlxG.stage != null && FlxG.stage.application != null && FlxG.stage.application.window != null)
			{
				var refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
				if (refreshRate > 0)
					return Std.int(FlxMath.bound(refreshRate, 30, 240));
			}
		}
		catch (e:Dynamic)
		{
			// Fallback to the gameplay framerate when refresh rate is unavailable.
		}
		#end

		return safeFramerate;
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic
	{
		if(!customDefaultValue) defaultValue = defaultData.gameplaySettings.get(name);
		return /*PlayState.isStoryMode ? defaultValue : */ (data.gameplaySettings.exists(name) ? data.gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadVolumeKeys()
	{
		TitleState.muteKeys = keyBinds.get('volume_mute').copy();
		TitleState.volumeDownKeys = keyBinds.get('volume_down').copy();
		TitleState.volumeUpKeys = keyBinds.get('volume_up').copy();
		toggleVolumeKeys(true);
	}
	public static function toggleVolumeKeys(?turnOn:Bool = true)
	{
		final emptyArray = [];
		FlxG.sound.muteKeys = (!Controls.instance.mobileC && turnOn) ? TitleState.muteKeys : emptyArray;
		FlxG.sound.volumeDownKeys = (!Controls.instance.mobileC && turnOn) ? TitleState.volumeDownKeys : emptyArray;
		FlxG.sound.volumeUpKeys = (!Controls.instance.mobileC && turnOn) ? TitleState.volumeUpKeys : emptyArray;
	}
}

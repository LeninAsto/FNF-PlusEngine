package options;

import objects.Character;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	var antialiasingOption:Int;
	var boyfriend:Character = null;
	public function new()
	{
		title = Language.getPhrase('graphics_menu', 'Graphics Settings');
		rpcTitle = 'Graphics Settings Menu'; //for Discord Rich Presence

		boyfriend = new Character(840, 170, 'bf', true);
		boyfriend.setGraphicSize(Std.int(boyfriend.width * 0.75));
		boyfriend.updateHitbox();
		boyfriend.dance();
		boyfriend.animation.finishCallback = function (name:String) boyfriend.dance();
		boyfriend.visible = false;

		//I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Low Quality', //Name
			'If checked, disables some background details,\ndecreases loading times and improves performance.', //Description
			'lowQuality', //Save data variable name
			BOOL); //Variable type
		addOption(option);

		var option:Option = new Option('Anti-Aliasing',
			'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			'antialiasing',
			BOOL);
		option.onChange = onChangeAntiAliasing; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);
		antialiasingOption = optionsArray.length-1;

		var option:Option = new Option('Shaders', //Name
			"If unchecked, disables shaders.\nIt's used for some visual effects, and also CPU intensive for weaker " + Main.platform + ".", //Description
			'shaders',
			BOOL);
		addOption(option);

		var option:Option = new Option('Color Accessibility',
		    "Select several options according to your color blindness disorder.",
			'colorblindMode',
			STRING,
			['None', 'Protanopia', 'Protanomaly', 'Deuteranopia', 'Deuteranomaly', 'Tritanopia', 'Tritanomaly', 'Achromatopsia', 'Achromatomaly']);
		option.onChange = () -> {
			ClientPrefs.saveSettings();
			shaders.ColorblindFilter.UpdateColors();
		};
		addOption(option);

		var option:Option = new Option('GPU Caching', //Name
			"If checked, allows the GPU to be used for caching textures, decreasing RAM usage.\nDon't turn this on if you have a shitty Graphics Card.", //Description
			'cacheOnGPU',
			BOOL);
		addOption(option);

		#if native
		var option:Option = new Option('VSync',
			'If checked, enables VSync, fixing screen tearing at the cost of capping FPS to the monitor refresh rate.\nRestart the game to fully apply it.',
			'vsync',
			BOOL);
		option.onChange = onChangeVSync;
		addOption(option);
		#end

		#if !html5 //Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		var option:Option = new Option('Framerate Mode',
			'Choose how the engine handles update/draw timing.\nInterpolated is smoother, Fixed is lighter, Base matches the original mobile base.\nRestart the game to apply changes.',
			'framerateMode',
			STRING,
			ClientPrefs.FRAMERATE_MODES);
		addOption(option);

		var option:Option = new Option('Framerate',
			"Pretty self explanatory, isn't it?\nRestart the game to apply changes.",
			'framerate',
			INT);
		addOption(option);

		final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
		option.minValue = 60;
		option.maxValue = 240;
		option.defaultValue = Std.int(FlxMath.bound(refreshRate, option.minValue, option.maxValue));
		option.displayFormat = '%v FPS';
		#end

		#if windows
		var option:Option = new Option('Fullscreen Mode',
			'Choose how fullscreen behaves: borderless, borderless fix or exclusive fullscreen.',
			'fullscreenMode',
			STRING,
			['Borderless', 'Borderless Fix', 'Exclusive']);
		addOption(option);
		#end

		super();
		insert(1, boyfriend);
	}

	function onChangeAntiAliasing()
	{
		for (sprite in members)
		{
			var sprite:FlxSprite = cast sprite;
			if(sprite != null && (sprite is FlxSprite) && !(sprite is FlxText)) {
				sprite.antialiasing = ClientPrefs.data.antialiasing;
			}
		}
	}

	#if native
	function onChangeVSync()
		lime.app.Application.current.window.vsync = ClientPrefs.data.vsync;
	#end

	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);
		boyfriend.visible = (antialiasingOption == curSelected);
	}
}

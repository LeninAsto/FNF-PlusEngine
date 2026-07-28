package mobile.options;

import backend.Mods;
import options.BaseOptionsMenu;
import options.Option;
#if android
import mobile.backend.StorageUtil;
#end

class MobileSettingsSubState extends BaseOptionsMenu
{
	final exControlTypes:Array<String> = ["NONE", "SINGLE", "DOUBLE"];
	final hintOptions:Array<String> = ["No Gradient", "No Gradient (Old)", "Gradient", "Hidden"];
	final fpsCounterOptions:Array<String> = ['Hidden', 'Visible No Background', 'Visible with Background', 'Basic Debug', 'Extended Debug'];
	#if android
	final storageOptions:Array<String> = ["INTERNAL", "EXTERNAL"];
	#end
	var option:Option;

	public function new()
	{
		title = Language.getPhrase('mobile_menu', 'Mobile Settings');
		rpcTitle = 'Mobile Settings Menu'; // for Discord Rich Presence, fuck it

		option = new Option('Extra Controls', 'Select how many extra buttons you prefer to have?\nThey can be used for mechanics with LUA or HScript.',
			'extraButtons', STRING, exControlTypes);
		addOption(option);

		option = new Option('Mobile Controls Opacity',
			'Selects the opacity for the mobile buttons (careful not to put it at 0 and lose track of your buttons).', 'controlsAlpha', PERCENT);
		option.scrollSpeed = 1;
		option.minValue = 0.001;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = () ->
		{
			touchPad.alpha = curOption.getValue();
			ClientPrefs.toggleVolumeKeys();
		};
		addOption(option);

		#if mobile
		option = new Option('Allow Phone Screensaver',
			'If checked, the phone will sleep after going inactive for few seconds.\n(The time depends on your phone\'s options)', 'screensaver', BOOL);
		option.onChange = () -> lime.system.System.allowScreenTimeout = curOption.getValue();
		addOption(option);

		option = new Option('Infinity Display',
			'If checked, extends the viewport vertically for taller screens while keeping the classic 16:9 gameplay area.',
			'infinityDisplay', BOOL);
		option.onChange = () -> FlxG.scaleMode = new mobile.backend.MobileScaleMode();
		addOption(option);
		#end

		if (MobileData.mode == 3)
		{
			option = new Option('Hitbox Design', 'Choose how your hitbox should look like.', 'hitboxType', STRING, hintOptions);
			addOption(option);

			option = new Option('Hitbox Position', 'If checked, the hitbox will be put at the bottom of the screen, otherwise will stay at the top.',
				'hitboxPos', BOOL);
			addOption(option);
		}

		option = new Option('Dynamic Controls Color',
			'If checked, the mobile controls color will be set to the notes color in your settings.\n(have effect during gameplay only)', 'dynamicColors',
			BOOL);
		addOption(option);

		option = new Option('Touch Pointer',
			'If checked, shows a touch pointer overlay for taps and drags.',
			'showTouchPointer',
			BOOL);
		addOption(option);

		option = new Option('Mobile Trace Button',
			'If checked, shows the trace touch button on mobile builds.',
			'showMobileDebugButtons',
			BOOL);
		option.onChange = () ->
		{
			if (Main.traceButton != null)
				Main.traceButton.updatePosition();
		};
		addOption(option);

		option = new Option('FPS Counter Mode',
			'Choose how much performance info is shown in the top-left overlay.',
			'fpsCounterMode',
			STRING,
			fpsCounterOptions);
		option.onChange = () ->
		{
			ClientPrefs.normalizeFPSCounterPrefs();
			if (Main.fpsVar != null)
			{
				Main.fpsVar.applyPrefs();
				Main.fpsVar.positionFPS(10, 3, 1.0);
			}
		};
		addOption(option);

		option = new Option('Align Receptors to Hitbox',
			'If checked, aligns mobile receptors with hitbox lanes. Useful for some layouts, but it can break scripts.',
			'mobileReceptorAlign',
			BOOL);
		addOption(option);

		#if android
		option = new Option('Mods Storage Location',
			'Choose where Android mods and saved files should live.\nINTERNAL uses scoped app storage, EXTERNAL uses public storage.',
			'storageType', STRING, storageOptions);
		option.onChange = () ->
		{
			StorageUtil.saveStorageTypePreference(curOption.getValue());
			#if MODS_ALLOWED
			Mods.updatedOnState = false;
			#end
			if (curOption.getValue() == 'EXTERNAL')
				StorageUtil.requestPermissions();
		};
		addOption(option);
		#end

		super();
	}
}

package options;

class VSliceSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = Language.getPhrase('vslice_menu', 'VSlice Settings');
		rpcTitle = 'VSlice Settings Menu';

		var option:Option = new Option('Naughtyness', 'Allows Funkin/VSlice content marked as explicit to be shown.', 'vsliceNaughtyness', BOOL, null,
			'vsliceNaughtyness');
		option.onChange = syncVSlicePreferences;
		addOption(option);

		var option:Option = new Option('Subtitles', 'Shows Funkin/VSlice subtitles during songs and cutscenes that provide them.', 'vsliceSubtitles', BOOL,
			null, 'vsliceSubtitles');
		option.onChange = syncVSlicePreferences;
		addOption(option);

		var option:Option = new Option('Strumline Background', 'Adds the Funkin/VSlice translucent background behind receptors.',
			'vsliceStrumlineBackgroundOpacity', INT, null, 'vsliceStrumlineBackgroundOpacity');
		option.minValue = 0;
		option.maxValue = 100;
		option.changeValue = 5;
		option.scrollSpeed = 50;
		option.displayFormat = '%v%';
		option.onChange = syncVSlicePreferences;
		addOption(option);

		var option:Option = new Option('Auto Fullscreen', 'Lets the Funkin/VSlice runtime request fullscreen on startup.', 'vsliceAutoFullscreen', BOOL, null,
			'vsliceAutoFullscreen');
		option.onChange = syncVSlicePreferences;
		addOption(option);

		var option:Option = new Option('Screenshot Hide Mouse', 'Hides the mouse cursor while Funkin/VSlice screenshots are captured.',
			'vsliceScreenshotHideMouse', BOOL, null, 'vsliceScreenshotHideMouse');
		option.onChange = syncVSlicePreferences;
		addOption(option);

		var option:Option = new Option('Screenshot Preview', 'Shows the Funkin/VSlice screenshot preview after capturing.', 'vsliceScreenshotFancyPreview',
			BOOL, null, 'vsliceScreenshotFancyPreview');
		option.onChange = syncVSlicePreferences;
		addOption(option);

		var option:Option = new Option('Preview Only After Save', 'Only shows the Funkin/VSlice screenshot preview when the image was saved.',
			'vsliceScreenshotPreviewOnSave', BOOL, null, 'vsliceScreenshotPreviewOnSave');
		option.onChange = syncVSlicePreferences;
		addOption(option);

		var option:Option = new Option('Haptics', 'Controls Funkin/VSlice vibration feedback where the target supports it.', 'vsliceHapticsMode', STRING,
			['All', 'Notes Only', 'None'], 'vsliceHapticsMode');
		option.onChange = syncVSlicePreferences;
		addOption(option);

		var option:Option = new Option('Haptics Intensity', 'Scales Funkin/VSlice vibration strength where the target supports it.', 'vsliceHapticsIntensity',
			FLOAT, null, 'vsliceHapticsIntensity');
		option.minValue = 0;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.scrollSpeed = 1;
		option.decimals = 1;
		option.displayFormat = '%vx';
		option.onChange = syncVSlicePreferences;
		addOption(option);

		super();
	}

	function syncVSlicePreferences():Void
	{
		ClientPrefs.saveSettings();
		#if vslice
		funkin.plus.VSlicePreferencesBridge.syncFromPlus();
		#end
	}
}


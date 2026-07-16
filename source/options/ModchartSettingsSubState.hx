package options;

/**
 * Submenu for modcharting-related options.
 * Allows users to configure settings that affect modchart performance and quality.
 * Note: Modchart Manager is now automatically enabled when onInitModchart() function is detected.
 */
class ModchartSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = Language.getPhrase('modchart_menu', 'Modchart Settings');
		rpcTitle = 'Modchart Options Menu'; // for Discord Rich Presence

		var option:Option = new Option('Modchart Debug Overlay',
			'Shows NotITG-style modchart renderer stats.\nDisabled by default because it has a performance cost.',
			'modchartDebug',
			BOOL);
		addOption(option);

		// 3D Camera option
		option = new Option('Enable 3D Cameras',
			'Enables or disables 3D camera functionality.\nDisabling this may improve performance by skipping 3D transformations.',
			'camera3dEnabled',
			BOOL);
		addOption(option);

		// Optimize Holds option
		var option:Option = new Option('Optimize Hold Rendering',
			'Optimizes hold arrow rendering for better performance.\nNOT recommended for complex modcharts as holds may look incorrect.',
			'optimizeHolds',
			BOOL);
		addOption(option);

		// Z Scale option
		var option:Option = new Option('Z-Axis Scale',
			'Scales the Z-axis values to control perceived depth.\nHigher values increase depth, lower values flatten it.',
			'zScale',
			FLOAT);
		option.scrollSpeed = 10;
		option.minValue = 0.1;
		option.maxValue = 5.0;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		super();
	}
}

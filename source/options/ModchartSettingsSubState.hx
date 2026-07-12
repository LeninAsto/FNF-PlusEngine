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

		// 3D Camera option
		var option:Option = new Option('Enable 3D Cameras',
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

		// Render Arrow Paths option
		var option:Option = new Option('Render Arrow Paths',
			'Renders the trajectory lines of arrows.\nWARNING: This affects performance due to path computation.',
			'renderArrowPaths',
			BOOL);
		addOption(option);

		// Styled Arrow Paths option
		var option:Option = new Option('Styled Arrow Paths',
			'Applies visual styles to arrow paths (color, scale, alpha).\nOnly works when "Render Arrow Paths" is enabled.',
			'styledArrowPaths',
			BOOL);
		addOption(option);

		// Arrow Path Quality option
		var option:Option = new Option('Arrow Path Quality',
			'Controls path rendering frequency.\nLower = Smoother paths (better quality, worse FPS)\nHigher = Faster rendering (lower quality, better FPS)\n(Recommended: 2-3)',
			'arrowPathFrameSkip',
			INT);
		option.scrollSpeed = 1;
		option.minValue = 1;
		option.maxValue = 6;
		option.changeValue = 1;
		option.decimals = 0;
		addOption(option);

		// Arrow Path Boundary option
		var option:Option = new Option('Arrow Path Boundary',
			'Pixels outside screen to still render paths.\nLower = Better FPS, Higher = Less pop-in\n(Recommended: 300)',
			'arrowPathBoundary',
			INT);
		option.scrollSpeed = 10;
		option.minValue = 0;
		option.maxValue = 1000;
		option.changeValue = 50;
		option.decimals = 0;
		addOption(option);

		// Hold End Scale option
		var option:Option = new Option('Hold End Scale',
			'Scales the size of hold note endings.\nAdjust for visual preference.',
			'holdEndScale',
			FLOAT);
		option.scrollSpeed = 10;
		option.minValue = 0.1;
		option.maxValue = 3.0;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		// Prevent Scaled Hold End option
		var option:Option = new Option('Prevent Scaled Hold Ends',
			'Prevents scaling the hold note endings.\nWARNING: May affect performance with many holds on screen.',
			'preventScaledHoldEnd',
			BOOL);
		addOption(option);

		// Column Specific Modifiers option
		var option:Option = new Option('Column Specific Modifiers',
			'Enables column-specific modifiers.\nDisabling may improve performance by reducing calculations.',
			'columnSpecificModifiers',
			BOOL);
		addOption(option);

		// Holds Behind Strum option
		var option:Option = new Option('Holds Behind Strums',
			'Shows sustain notes behind the strum line.\nVisual preference option.',
			'holdsBehindStrum',
			BOOL);
		addOption(option);

		super();
	}
}

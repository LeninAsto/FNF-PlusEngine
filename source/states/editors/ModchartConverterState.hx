package states.editors;

import backend.ui.PsychUIButton;
import lime.system.Clipboard;

using StringTools;

class ModchartConverterState extends MusicBeatState
{
	var statusText:FlxText;
	var previewText:FlxText;

	override function create()
	{
		FlxG.mouse.visible = true;
		FlxG.camera.bgColor = 0xFF10151D;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Modchart Converter');
		#end

		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, 0xFF10151D);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.scrollFactor.set();
		add(bg);

		var accent:FlxSprite = new FlxSprite(0, 0).makeGraphic(8, FlxG.height, 0xFF7AD6FF);
		accent.scrollFactor.set();
		add(accent);

		var title = new FlxText(24, 18, FlxG.width - 48, 'Modchart Converter', 32);
		title.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		title.scrollFactor.set();
		add(title);

		statusText = new FlxText(24, 64, FlxG.width - 48, 'Copy an NVME Lua modchart to the clipboard, and then click \"Convert Clipboard\"".', 18);
		statusText.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		statusText.scrollFactor.set();
		add(statusText);

		var helpText = new FlxText(24, 102, 420,
			'This tool performs a practical first-pass conversion.\n' +
			'Reassign the steps, remove the NVMe radian helpers, and remember that fieldYaw is the name of the Plus side.',
			16);
		helpText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.fromRGB(215, 225, 235), LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		helpText.scrollFactor.set();
		helpText.fieldWidth = 420;
		helpText.wordWrap = true;
		add(helpText);

		previewText = new FlxText(470, 24, FlxG.width - 494, '', 16);
		previewText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		previewText.scrollFactor.set();
		previewText.fieldWidth = FlxG.width - 494;
		previewText.wordWrap = true;
		add(previewText);

		var convertButton = new PsychUIButton(24, FlxG.height - 86, 'Convert Clipboard', function()
		{
			convertClipboard();
		});
		add(convertButton);

		var templateButton = new PsychUIButton(184, FlxG.height - 86, 'Copy Starter', function()
		{
			Clipboard.text = makeStarterTemplate();
			setStatus('The initial template has been copied to the clipboard.');
			showPreview(Clipboard.text);
		});
		add(templateButton);

		var backButton = new PsychUIButton(344, FlxG.height - 86, 'Back', function()
		{
			MusicBeatState.switchState(new MasterEditorMenu());
		});
		add(backButton);

		setStatus('Done. Import a modchart from the clipboard or copy the initial template.');
		showPreview(makeStarterTemplate());

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.BACK)
			MusicBeatState.switchState(new MasterEditorMenu());
	}

	function setStatus(message:String):Void
	{
		statusText.text = message;
	}

	function showPreview(text:String):Void
	{
		if (text == null)
		{
			previewText.text = '';
			return;
		}

		var preview = text;
		if (preview.length > 1800)
			preview = preview.substr(0, 1800) + '\n\n... preview truncated ...';

		previewText.text = preview;
	}

	function convertClipboard():Void
	{
		var source = Clipboard.text;
		if (source == null || source.trim().length == 0)
		{
			setStatus('The clipboard is empty. First, copy an NVMe script.');
			showPreview('No text was found in the clipboard.');
			return;
		}

		var converted = convertNvmToPlus(source);
		Clipboard.text = converted;
		setStatus('Converts ' + source.length + ' characters in ' + converted.length + ' and copied to the clipboard again.');
		showPreview(converted);
	}

	function convertNvmToPlus(source:String):String
	{
		var out = source.replace('\r\n', '\n');

		// Remove NVMe-specific helpers so that the values are in Plus units.
		out = out.replace("local function p(value)\n    return value / 100\nend\n\n", "");
		out = out.replace("local function tr(deg)\n    return math.rad(deg)\nend\n\n", "");

		// Mapping names on the first pass.
		out = out.replace('scheduleSetPercent(', 'scheduleSet(');
		out = out.replace('scheduleEasePercent(', 'scheduleEase(');

		// Remove the helper wrappers after rewriting the calls.
		out = out.replace('p(', '(');
		out = out.replace('tr(', '(');
		out = out.replace('math.rad(', '(');

		return '-- Converted from NVMe to Plus Engine\n'
			+ '-- fieldX, fieldY, fieldDepth, and fieldYaw are submods of the Field modifier.\n'
			+ '-- Manually check any custom camera math, because that\'s where the most delicate part lies.\n\n'
			+ out;
	}

	function makeStarterTemplate():String
	{
		return [
			'-- Initial template for converting NVMe modcharts in Plus Engine',
			'function onInitModchart()',
			'    addModifier(\'transform\')',
			'    addModifier(\'localrotate\')',
			'    addModifier(\'centerrotate\')',
			'    addModifier(\'field\')',
			'',
			'    -- Guia rapida de mapeo:',
			'    -- yaw    -> fieldYaw (field submodule)',
			'    -- depth  -> fieldDepth (field submode) or z adjustment / zoffset',
			'    -- fieldX -> fieldX (field submod) or transformX, depending on the intended use',
			'    -- fieldY -> fieldY (field submod) or transformY, depending on the intended use',
			'    -- tr(x)  -> x (Plus uses degrees directly)',
			'end'
		].join('\n');
	}
}


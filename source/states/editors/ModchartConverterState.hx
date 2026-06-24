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

		statusText = new FlxText(24, 64, FlxG.width - 48, 'Copia un modchart Lua de NVME al portapapeles y luego pulsa Convert Clipboard.', 18);
		statusText.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		statusText.scrollFactor.set();
		add(statusText);

		var helpText = new FlxText(24, 102, 420,
			'Esta herramienta hace una conversion practica de primera pasada.\n' +
			'Reasigna steps, elimina helpers de radianes de NVME y recuerda que fieldYaw es el nombre del lado de Plus.', 16);
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
			setStatus('Plantilla inicial copiada al portapapeles.');
			showPreview(Clipboard.text);
		});
		add(templateButton);

		var backButton = new PsychUIButton(344, FlxG.height - 86, 'Back', function()
		{
			MusicBeatState.switchState(new MasterEditorMenu());
		});
		add(backButton);

		setStatus('Listo. Convierte un modchart desde el portapapeles o copia la plantilla inicial.');
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
			setStatus('El portapapeles esta vacio. Copia primero un script de NVME.');
			showPreview('No se encontro texto en el portapapeles.');
			return;
		}

		var converted = convertNvmToPlus(source);
		Clipboard.text = converted;
		setStatus('Convertidos ' + source.length + ' caracteres en ' + converted.length + ' y copiados otra vez al portapapeles.');
		showPreview(converted);
	}

	function convertNvmToPlus(source:String):String
	{
		var out = source.replace('\r\n', '\n');

		// Quita helpers exclusivos de NVME para que los valores queden en grados de Plus.
		out = out.replace("local function p(value)\n    return value / 100\nend\n\n", "");
		out = out.replace("local function tr(deg)\n    return math.rad(deg)\nend\n\n", "");

		// Mapeo de nombres en una primera pasada.
		out = out.replace('scheduleSetPercent(', 'scheduleSet(');
		out = out.replace('scheduleEasePercent(', 'scheduleEase(');

		// Quita los wrappers de ayuda despues de reescribir las llamadas.
		out = out.replace('p(', '(');
		out = out.replace('tr(', '(');
		out = out.replace('math.rad(', '(');

		return '-- Convertido de NVME a Plus Engine\n'
			+ '-- fieldX, fieldY, fieldDepth y fieldYaw son submods del modificador Field.\n'
			+ '-- Revisa manualmente cualquier matematica de camara personalizada, porque ahi esta la parte mas delicada.\n\n'
			+ out;
	}

	function makeStarterTemplate():String
	{
		return [
			'-- Plantilla inicial para convertir modcharts de NVME en Plus Engine',
			'function onInitModchart()',
			'    addModifier(\'transform\')',
			'    addModifier(\'localrotate\')',
			'    addModifier(\'centerrotate\')',
			'    addModifier(\'field\')',
			'',
			'    -- Guia rapida de mapeo:',
			'    -- yaw    -> fieldYaw (submod de field)',
			'    -- depth  -> fieldDepth (submod de field) o ajuste de z / zoffset',
			'    -- fieldX -> fieldX (submod de field) o transformX segun la intencion',
			'    -- fieldY -> fieldY (submod de field) o transformY segun la intencion',
			'    -- tr(x)  -> x (Plus usa grados directamente)',
			'end'
		].join('\n');
	}
}

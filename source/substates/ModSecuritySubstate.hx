package substates;

#if MODS_ALLOWED
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.ModSecurity;

/**
 * Per-mod trust prompt. Shown by MainMenuState when scanning enabled mods
 * surfaces sensitive APIs whose use the user hasn't yet decided on.
 *
 * Iterates through `pending` one mod at a time. Each decision is persisted
 * via ModSecurity.setDecision() the moment the user confirms.
 */
class ModSecuritySubstate extends MusicBeatSubstate {
	// Patterns we still scan/track but don't surface in the prompt because
	// they're so common that listing them just adds noise. The mod can still
	// trip the prompt via *other* sensitive APIs; this only filters display.
	static final HIDDEN_FROM_DISPLAY:Map<String, Bool> = [
		"runHaxeCode" => true,
		"runHaxeFunction" => true,
		"addHaxeLibrary" => true,
	];

	// Categorize each pattern. Used to surface concrete, human-readable
	// warnings ("This mod can save files to your PC", etc.) instead of raw
	// API names. Anything not in this map is treated as "other".
	static final PATTERN_CATEGORY:Map<String, String> = [
		// File writes / deletes
		"saveFile" => "fs_write", "deleteFile" => "fs_write",
		"os.remove" => "fs_write", "os.rename" => "fs_write",
		// File reads
		"getTextFromFile" => "fs_read", "io.open" => "fs_read",
		"sys.io.File" => "fs_write", "sys.FileSystem" => "fs_write",
		// External command execution
		"os.execute" => "exec", "io.popen" => "exec",
		"Sys.command" => "exec", "sys.io.Process" => "exec",
		"cpp.Lib.load" => "exec",
		// Arbitrary Haxe / Lua eval
		"runHaxeCode" => "haxe_eval", "runHaxeFunction" => "haxe_eval",
		"addHaxeLibrary" => "haxe_eval",
		"loadstring" => "haxe_eval", "dofile" => "haxe_eval", "loadfile" => "haxe_eval",
		// Reflection / dynamic class lookup
		"Type.resolveClass" => "reflect", "Type.createInstance" => "reflect",
		"Reflect.callMethod" => "reflect",
		"import sys" => "reflect", "import cpp" => "reflect", "import Sys" => "reflect",
		"openfl.Lib.application" => "reflect",
		// Process exit
		"Sys.exit" => "exit", "os.exit" => "exit",
		// Environment / system info recon
		"os.getenv" => "recon", "os.tmpname" => "recon", "os.setlocale" => "recon",
		// Direct attempts to tamper with the security system itself
		"ModSecurity (tamper)" => "tamper",
	];

	// Order matters: categories shown in this order in the warning panel.
	static final CATEGORY_ORDER:Array<String> = ["tamper", "exec", "fs_write", "haxe_eval", "fs_read", "reflect", "exit", "recon"];

	static final CATEGORY_LABELS:Map<String, String> = [
		"tamper"    => "[!!] Attempts to tamper with the mod security system itself",
		"exec"      => "[!] Runs external programs / commands on your PC",
		"fs_write"  => "[!] Writes, modifies or deletes files on your PC",
		"haxe_eval" => "[!] Executes arbitrary Haxe/Lua code at runtime",
		"fs_read"   => "[*] Reads files from your PC",
		"reflect"   => "[*] Uses reflection / dynamic class lookup",
		"exit"      => "[*] Can force-quit the game process",
		"recon"     => "[*] Reads environment variables / system info",
	];

	// Panel layout (centered)
	static inline final PANEL_W:Int = 900;
	static inline final PANEL_H:Int = 560;
	static inline final BORDER:Int = 3;
	// Scrollable findings list area (relative to panel top)
	static inline final LIST_TOP:Int = 280;
	static inline final LIST_LINES:Int = 9; // visible rows
	static inline final LIST_LINE_H:Int = 18;

	var pending:Array<String>;
	var currentIdx:Int = 0;

	var bg:FlxSprite;
	var panelBorder:FlxSprite;
	var panel:FlxSprite;
	var headerBar:FlxSprite;

	var titleTxt:FlxText;
	var subTitleTxt:FlxText;
	var bodyTxt:FlxText;
	var listHeaderTxt:FlxText;
	var listTxt:FlxText;
	var listScrollHint:FlxText;
	var hintTxt:FlxText;
	var counterTxt:FlxText;

	// Scrollable findings list state for the current mod.
	var displayFindings:Array<ModSecurityFinding> = [];
	var listScroll:Int = 0;

	var trustTxt:Alphabet;
	var blockTxt:Alphabet;
	var trustBg:flixel.FlxSprite;
	var blockBg:flixel.FlxSprite;
	var selectArrowL:FlxText;
	var selectArrowR:FlxText;
	var onTrust:Bool = false;

	// Anchor points (panel-relative) for repositioning the choice buttons each
	// time their scale changes; cached in create() to avoid recomputation.
	var trustCenterX:Float = 0;
	var blockCenterX:Float = 0;
	var btnCenterY:Float = 0;

	public function new(pending:Array<String>) {
		super();
		this.pending = pending;
	}

	override function create() {
		super.create();

		#if mobile
		addTouchPad('FULL', 'A_B');
		#end

		// Full-screen dimmer
		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0.78;
		bg.scrollFactor.set();
		add(bg);

		final px:Float = (FlxG.width - PANEL_W) * 0.5;
		final py:Float = (FlxG.height - PANEL_H) * 0.5;

		// Border (slightly larger than panel, drawn behind it)
		panelBorder = new FlxSprite(px - BORDER, py - BORDER).makeGraphic(1, 1, 0xFFFFD24A);
		panelBorder.scale.set(PANEL_W + BORDER * 2, PANEL_H + BORDER * 2);
		panelBorder.updateHitbox();
		panelBorder.scrollFactor.set();
		add(panelBorder);

		// Panel body
		panel = new FlxSprite(px, py).makeGraphic(1, 1, 0xFF14161E);
		panel.scale.set(PANEL_W, PANEL_H);
		panel.updateHitbox();
		panel.alpha = 0.96;
		panel.scrollFactor.set();
		add(panel);

		// Header strip
		headerBar = new FlxSprite(px, py).makeGraphic(1, 1, 0xFF1F2230);
		headerBar.scale.set(PANEL_W, 70);
		headerBar.updateHitbox();
		headerBar.scrollFactor.set();
		add(headerBar);

		titleTxt = new FlxText(px + 18, py + 10, PANEL_W - 200, "Sensitive API Warning", 22);
		titleTxt.setFormat(Paths.font("vcr.ttf"), 22, 0xFFFFD24A, LEFT, OUTLINE, FlxColor.BLACK);
		titleTxt.borderSize = 1.5;
		titleTxt.scrollFactor.set();
		add(titleTxt);

		counterTxt = new FlxText(px, py + 18, PANEL_W - 18, "", 16);
		counterTxt.setFormat(Paths.font("vcr.ttf"), 16, 0xFFB0B0B0, RIGHT, OUTLINE, FlxColor.BLACK);
		counterTxt.borderSize = 1;
		counterTxt.scrollFactor.set();
		add(counterTxt);

		subTitleTxt = new FlxText(px + 18, py + 38, PANEL_W - 36, "", 18);
		subTitleTxt.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		subTitleTxt.borderSize = 1.25;
		subTitleTxt.scrollFactor.set();
		add(subTitleTxt);

		bodyTxt = new FlxText(px + 18, py + 86, PANEL_W - 36, "", 15);
		bodyTxt.setFormat(Paths.font("vcr.ttf"), 15, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		bodyTxt.borderSize = 1.25;
		bodyTxt.scrollFactor.set();
		add(bodyTxt);

		listHeaderTxt = new FlxText(px + 18, py + LIST_TOP - 22, PANEL_W - 36, "Detected calls (UP/DOWN or wheel to scroll):", 13);
		listHeaderTxt.setFormat(Paths.font("vcr.ttf"), 13, 0xFFB0B0B0, LEFT, OUTLINE, FlxColor.BLACK);
		listHeaderTxt.borderSize = 1;
		listHeaderTxt.scrollFactor.set();
		add(listHeaderTxt);

		listTxt = new FlxText(px + 18, py + LIST_TOP, PANEL_W - 36, "", 13);
		listTxt.setFormat(Paths.font("vcr.ttf"), 13, 0xFFCCCCCC, LEFT, OUTLINE, FlxColor.BLACK);
		listTxt.borderSize = 1;
		listTxt.scrollFactor.set();
		add(listTxt);

		listScrollHint = new FlxText(px + 18, py + LIST_TOP + LIST_LINES * LIST_LINE_H + 2, PANEL_W - 36, "", 12);
		listScrollHint.setFormat(Paths.font("vcr.ttf"), 12, 0xFF888888, RIGHT, OUTLINE, FlxColor.BLACK);
		listScrollHint.borderSize = 1;
		listScrollHint.scrollFactor.set();
		add(listScrollHint);

		// Choice buttons inside the panel
		final btnY:Float = py + PANEL_H - 90;
		trustCenterX = px + PANEL_W * 0.30;
		blockCenterX = px + PANEL_W * 0.70;
		btnCenterY = btnY;

		// Highlight backplate behind the currently selected option. A solid
		// colored pill is far more obvious than just tinting letter colors.
		trustBg = new flixel.FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		trustBg.scrollFactor.set();
		trustBg.visible = false;
		add(trustBg);
		blockBg = new flixel.FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		blockBg.scrollFactor.set();
		blockBg.visible = false;
		add(blockBg);

		trustTxt = new Alphabet(0, btnY, "TRUST", true);
		trustTxt.scrollFactor.set();
		add(trustTxt);

		blockTxt = new Alphabet(0, btnY, "BLOCK", true);
		blockTxt.scrollFactor.set();
		add(blockTxt);

		selectArrowL = new FlxText(0, btnY, 40, ">", 36);
		selectArrowL.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.YELLOW, CENTER, OUTLINE, FlxColor.BLACK);
		selectArrowL.borderSize = 2;
		selectArrowL.scrollFactor.set();
		add(selectArrowL);

		selectArrowR = new FlxText(0, btnY, 40, "<", 36);
		selectArrowR.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.YELLOW, CENTER, OUTLINE, FlxColor.BLACK);
		selectArrowR.borderSize = 2;
		selectArrowR.scrollFactor.set();
		add(selectArrowR);

		hintTxt = new FlxText(px, py + PANEL_H - 28, PANEL_W, "Left/Right to choose -- Enter to confirm", 14);
		hintTxt.setFormat(Paths.font("vcr.ttf"), 14, 0xFFB0B0B0, CENTER, OUTLINE, FlxColor.BLACK);
		hintTxt.borderSize = 1;
		hintTxt.scrollFactor.set();
		add(hintTxt);

		showCurrent();
		updateOptions();
	}

	function showCurrent():Void {
		if (currentIdx >= pending.length) {
			close();
			return;
		}
		final folder = pending[currentIdx];
		// Ensure the mod has been scanned so a proactively-opened review (no prior
		// record) shows accurate findings rather than a false "clean".
		ModSecurity.isBlocked(folder);
		final rec = ModSecurity.records.get(folder);

		counterTxt.text = 'Mod ${currentIdx + 1} / ${pending.length}';
		subTitleTxt.text = '"$folder"';

		// Collect categories present and build the displayable findings list.
		displayFindings = [];
		listScroll = 0;

		final seenCat = new Map<String, Bool>();
		if (rec != null) {
			final findings = rec.findings;
			final fLen = findings.length;
			for (i in 0...fLen) {
				final f = findings[i];
				if (HIDDEN_FROM_DISPLAY.exists(f.pattern)) continue;
				displayFindings.push(f);
				final cat = PATTERN_CATEGORY.exists(f.pattern) ? PATTERN_CATEGORY.get(f.pattern) : "other";
				if (!seenCat.exists(cat))
					seenCat.set(cat, true);
			}
		}

		final hasFindings:Bool = displayFindings.length > 0;
		final body = new StringBuf();

		if (!hasFindings) {
			// Clean mod (or all findings filtered): this reads as a settings view,
			// letting the user proactively trust/block even with nothing flagged.
			titleTxt.text = 'Mod Security';
			body.add('No sensitive APIs were detected in this mod\'s scripts.\n\n');
			body.add('TRUST = scripts run normally.\n');
			body.add('BLOCK = mod stays enabled, scripts skipped.');
		} else {
			titleTxt.text = 'Sensitive API Warning';
			body.add('This mod\'s scripts use APIs that can be abused for harm.\n');
			body.add('TRUST = scripts run normally.   BLOCK = mod stays enabled, scripts skipped.\n');
			body.add('\nThis mod can:');
			var anyCat:Bool = false;
			final orderLen = CATEGORY_ORDER.length;
			for (i in 0...orderLen) {
				final cat = CATEGORY_ORDER[i];
				if (!seenCat.exists(cat)) continue;
				anyCat = true;
				body.add('\n  ');
				body.add(CATEGORY_LABELS.get(cat));
			}
			if (seenCat.exists("other")) {
				body.add('\n  [*] Other sensitive APIs (see list below)');
				anyCat = true;
			}
			if (!anyCat)
				body.add('\n  (only common APIs found -- review the list below)');
		}

		bodyTxt.text = body.toString();
		// Default cursor: for a clean mod (or one the user already decided on),
		// reflect the CURRENT trust state. A brand-new prompt that actually has
		// findings starts on BLOCK as the safer default.
		if (!hasFindings || (rec != null && rec.decided))
			onTrust = (rec == null || rec.allowed);
		else
			onTrust = false;
		refreshList();
	}

	function refreshList():Void {
		final total:Int = displayFindings.length;
		if (total == 0) {
			listTxt.text = '  (no sensitive APIs detected)';
			listScrollHint.text = '';
			return;
		}
		// Clamp scroll
		final maxScroll:Int = (total > LIST_LINES) ? (total - LIST_LINES) : 0;
		if (listScroll < 0) listScroll = 0;
		else if (listScroll > maxScroll) listScroll = maxScroll;

		final buf = new StringBuf();
		final endIdx:Int = (listScroll + LIST_LINES > total) ? total : (listScroll + LIST_LINES);
		for (i in listScroll...endIdx) {
			final f = displayFindings[i];
			if (i > listScroll) buf.add('\n');
			buf.add(f.file);
			buf.add(':');
			buf.add(Std.string(f.line));
			buf.add('  ');
			buf.add(f.pattern);
		}
		listTxt.text = buf.toString();
		if (total > LIST_LINES) {
			listScrollHint.text = '${listScroll + 1}-${endIdx} of ${total}';
		} else {
			listScrollHint.text = '${total} item' + (total == 1 ? '' : 's');
		}
	}

	function updateOptions():Void {
		// Selected option: full size, vivid color (green/red), full alpha.
		// Unselected: shrunk + dimmed white so the contrast is unmistakable
		// even for users who don't immediately read the color difference.
		final selectedScale:Float = 1.0;
		final unselectedScale:Float = 0.65;
		final selectedAlpha:Float = 1.0;
		final unselectedAlpha:Float = 0.4;

		final trustSel:Bool = onTrust;
		final blockSel:Bool = !onTrust;

		trustTxt.setScale(trustSel ? selectedScale : unselectedScale);
		trustTxt.alpha = trustSel ? selectedAlpha : unselectedAlpha;
		blockTxt.setScale(blockSel ? selectedScale : unselectedScale);
		blockTxt.alpha = blockSel ? selectedAlpha : unselectedAlpha;

		final trustColor:FlxColor = trustSel ? 0xFF22FF55 : 0xFFAAAAAA;
		final blockColor:FlxColor = blockSel ? 0xFFFF3344 : 0xFFAAAAAA;
		final tLetters = trustTxt.letters;
		final tLen:Int = tLetters.length;
		for (i in 0...tLen) tLetters[i].color = trustColor;
		final bLetters = blockTxt.letters;
		final bLen:Int = bLetters.length;
		for (i in 0...bLen) bLetters[i].color = blockColor;

		// Recenter on the cached anchor points now that widths changed.
		trustTxt.x = trustCenterX - trustTxt.width * 0.5;
		trustTxt.y = btnCenterY + (1.0 - (trustSel ? selectedScale : unselectedScale)) * 22;
		blockTxt.x = blockCenterX - blockTxt.width * 0.5;
		blockTxt.y = btnCenterY + (1.0 - (blockSel ? selectedScale : unselectedScale)) * 22;

		// Highlight backplate sized to fit the selected button.
		final selTxt = trustSel ? trustTxt : blockTxt;
		final selBg = trustSel ? trustBg : blockBg;
		final otherBg = trustSel ? blockBg : trustBg;
		final padX:Float = 24;
		final padY:Float = 12;
		selBg.visible = true;
		selBg.color = trustSel ? 0xFF0E3A18 : 0xFF3A0E14;
		selBg.alpha = 0.85;
		selBg.setGraphicSize(Std.int(selTxt.width + padX * 2), Std.int(selTxt.height + padY * 2));
		selBg.updateHitbox();
		selBg.x = selTxt.x - padX;
		selBg.y = selTxt.y - padY;
		otherBg.visible = false;

		// Pointer arrows hugging the selected button.
		final gap:Float = 8;
		selectArrowL.x = selTxt.x - selectArrowL.width - gap;
		selectArrowL.y = selTxt.y + (selTxt.height - selectArrowL.height) * 0.5;
		selectArrowR.x = selTxt.x + selTxt.width + gap;
		selectArrowR.y = selTxt.y + (selTxt.height - selectArrowR.height) * 0.5;
		selectArrowL.color = trustSel ? 0xFF22FF55 : 0xFFFF3344;
		selectArrowR.color = selectArrowL.color;
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
			close();
			return;
		}

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P) {
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			onTrust = !onTrust;
			updateOptions();
		}

		// Findings list scrolling -- UP/DOWN keys (held works via _P? we want
		// repeating, so use the non-_P variant gated by a simple cooldown).
		if (controls.UI_UP_P) {
			listScroll--;
			refreshList();
		} else if (controls.UI_DOWN_P) {
			listScroll++;
			refreshList();
		}
		if (FlxG.mouse.wheel != 0) {
			listScroll -= FlxG.mouse.wheel;
			refreshList();
		}

		if (controls.ACCEPT) {
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
			ModSecurity.setDecision(pending[currentIdx], onTrust);
			currentIdx++;
			showCurrent();
			updateOptions();
		}
	}
}
#end

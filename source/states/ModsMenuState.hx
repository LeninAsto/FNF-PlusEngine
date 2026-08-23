package states;

import backend.WeekData;
import backend.Mods;
import backend.ScriptableState;
import flixel.FlxBasic;
import flixel.graphics.FlxGraphic;
import flash.geom.Rectangle;
import haxe.Json;
import flixel.util.FlxSpriteUtil;
import objects.AttachedSprite;
import options.ModSettingsSubState;
import openfl.display.BitmapData;
import lime.utils.Assets;


class ModsMenuState extends MusicBeatState {
	static final FILTERS:Array<String> = ['ALL', 'ENABLED', 'DISABLED', 'LAUNCHABLE'];

	var bg:FlxSprite;
	var modsList:ModsList;
	var modsGroup:FlxTypedGroup<ModItem>; // every installed mod
	var view:Array<ModItem> = []; // the filtered/searched subset shown in the list
	var curSel:Int = 0;
	var scrollOffset:Int = 0; // index of the first visible row (top-anchored)

	// header
	var headerBar:FlxSprite;
	var titleTxt:Alphabet;
	var searchTxt:FlxText;
	var filterTxt:FlxText;

	// left list
	var bgList:FlxSprite;
	var noModsTxt:FlxText;
	var noModsSine:Float = 0;
	var nextAttempt:Float = 1;

	// right: hero banner + content
	var bgBanner:FlxSprite;
	var bannerImg:FlxSprite;
	var modName:Alphabet;
	var modLogo:FlxSprite; // shown instead of modName when the mod has a logo.png
	var contentTopY:Float; // top of the content sections (for dynamic reflow)
	var bgContent:FlxSprite;
	var descHeader:FlxText;
	var descTxt:FlxText;
	var featHeader:FlxText;
	var featTxt:FlxText;
	var clHeader:FlxText;
	var clTxt:FlxText;
	var modRestartText:FlxText;
	var launchStatus:FlxText;

	// bottom action bar
	var launchBtn:MenuButton;
	var enableBtn:MenuButton;
	var settingsBtn:MenuButton;
	var reloadBtn:MenuButton;
	var hintBar:FlxText;

	// state
	var searching:Bool = false;
	var query:String = '';
	var filterMode:Int = 0;
	var waitingToRestart:Bool = false;
	var holdTime:Float = 0;
	var startMod:String = null;
	var vsliceMode:Bool = false;
	var returnToSelector:Bool = false;
	var _lastControllerMode:Bool = false;

	// geometry (computed in create)
	var listX:Float;
	var listY:Float;
	var listW:Float;
	var listH:Float;
	var rowH:Float = 72;

	public function new(startMod:String = null, vsliceMode:Bool = false, returnToSelector:Bool = false) {
		this.startMod = startMod;
		this.vsliceMode = vsliceMode;
		this.returnToSelector = returnToSelector;
		super();
	}

	override function create() {
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		persistentUpdate = false;

		modsList = vsliceMode ? Mods.parseVSliceList() : Mods.parseList();
		if (vsliceMode)
			Mods.loadTopVSliceMod();
		else
			Mods.loadTopMod();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Mod Browser", null);
		#end

		var margin = 20.0;
		var headerH = 56.0;
		var bottomH = 70.0;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF808080;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		// ---- Header ----
		headerBar = FlxSpriteUtil.drawRoundRect(new FlxSprite(margin,
			margin).makeGraphic(Std.int(FlxG.width - margin * 2), Std.int(headerH), FlxColor.TRANSPARENT), 0, 0,
			Std.int(FlxG.width - margin * 2), Std.int(headerH), 15, 15, FlxColor.BLACK);
		headerBar.alpha = 0.6;
		add(headerBar);

		titleTxt = new Alphabet(margin + 18, margin + 8, 'MODS', true);
		titleTxt.setScale(0.6);
		add(titleTxt);

		filterTxt = new FlxText(0, margin + 16, 0, 'FILTER: ALL', 22);
		filterTxt.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		filterTxt.borderSize = 1.5;
		add(filterTxt);

		searchTxt = new FlxText(0, margin + 16, 0, 'SEARCH', 22);
		searchTxt.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		searchTxt.borderSize = 1.5;
		add(searchTxt);

		// ---- Left list ----
		listX = margin;
		listY = margin + headerH + 14;
		listW = 330;
		listH = FlxG.height - listY - bottomH - margin - 8;

		bgList = FlxSpriteUtil.drawRoundRect(new FlxSprite(listX, listY).makeGraphic(Std.int(listW), Std.int(listH), FlxColor.TRANSPARENT), 0, 0,
			Std.int(listW), Std.int(listH), 15, 15, FlxColor.BLACK);
		bgList.alpha = 0.6;
		add(bgList);

		modsGroup = new FlxTypedGroup<ModItem>();
		for (mod in modsList.all)
			modsGroup.add(new ModItem(mod, vsliceMode));

		// ---- Right: Banner ----
		var rightX = listX + listW + 16;
		var rightW = FlxG.width - rightX - margin;
		var bannerH = 196.0;

		bgBanner = FlxSpriteUtil.drawRoundRect(new FlxSprite(rightX, listY).makeGraphic(Std.int(rightW), Std.int(bannerH), FlxColor.TRANSPARENT), 0, 0,
			Std.int(rightW), Std.int(bannerH), 15, 15, FlxColor.BLACK);
		bgBanner.alpha = 0.55;
		add(bgBanner);

		bannerImg = new FlxSprite(rightX, listY);
		bannerImg.antialiasing = ClientPrefs.data.antialiasing;
		add(bannerImg);

		modName = new Alphabet(rightX + 18, listY + bannerH - 64, "", true);
		modName.setScale(0.9);
		add(modName);

		modLogo = new FlxSprite(rightX + 18, listY);
		modLogo.antialiasing = ClientPrefs.data.antialiasing;
		modLogo.visible = false;
		add(modLogo);

		// ---- Right: content (Description / Features / Changelog) ----
		var contentY = listY + bannerH + 12;
		var contentH = listH - bannerH - 12;
		bgContent = FlxSpriteUtil.drawRoundRect(new FlxSprite(rightX, contentY).makeGraphic(Std.int(rightW), Std.int(contentH), FlxColor.TRANSPARENT), 0, 0,
			Std.int(rightW), Std.int(contentH), 15, 15, FlxColor.BLACK);
		bgContent.alpha = 0.55;
		add(bgContent);

		var cx = rightX + 18;
		var cw = rightW - 36;
		var cy = contentY + 14;
		contentTopY = cy;

		descHeader = sectionHeader(cx, cy, 'DESCRIPTION');
		cy += 28;
		descTxt = sectionBody(cx, cy, cw, 78);
		cy += 84;
		featHeader = sectionHeader(cx, cy, 'FEATURES');
		cy += 28;
		featTxt = sectionBody(cx, cy, cw, 66);
		cy += 72;
		clHeader = sectionHeader(cx, cy, 'CHANGELOG');
		cy += 28;
		clTxt = sectionBody(cx, cy, cw, Std.int(contentY + contentH - cy - 30));

		modRestartText = new FlxText(cx, contentY + contentH - 24, cw, '* Moving/Toggling this mod will restart the game.', 14);
		modRestartText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, RIGHT);
		modRestartText.alpha = 0.8;
		add(modRestartText);

		launchStatus = new FlxText(rightX + 18, listY + 12, rightW - 36, "", 22);
		launchStatus.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		launchStatus.borderSize = 1.5;
		add(launchStatus);

		// ---- Bottom action bar ----
		var barY = FlxG.height - bottomH - margin + 4;
		var barW = FlxG.width - margin * 2;
		var btnW = Std.int((barW - 30) / 4);
		var bh = Std.int(bottomH - 8);

		launchBtn = new MenuButton(margin, barY, btnW, bh, Language.getPhrase('launch_button', 'LAUNCH'), launchSelected);
		launchBtn.bg.color = FlxColor.GREEN;
		launchBtn.focusChangeCallback = function(f) if (!f)
			launchBtn.bg.color = FlxColor.GREEN;
		add(launchBtn);

		enableBtn = new MenuButton(margin + (btnW + 10), barY, btnW, bh, Language.getPhrase('enable_button', 'ENABLE'), toggleSelected);
		add(enableBtn);

		settingsBtn = new MenuButton(margin + (btnW + 10) * 2, barY, btnW, bh, Language.getPhrase('settings_button', 'SETTINGS'), openSelectedSettings);
		add(settingsBtn);

		reloadBtn = new MenuButton(margin + (btnW + 10) * 3, barY, btnW, bh, Language.getPhrase('reload_button', 'RELOAD'), reload);
		add(reloadBtn);

		add(modsGroup);

		hintBar = new FlxText(margin, FlxG.height - 18, FlxG.width - margin * 2,
			vsliceMode ? 'UP/DOWN Select   L/R Reorder   SPACE On/Off (SHIFT=All)   F Filter   / Search   ESC Exit'
				: 'UP/DOWN Select   L/R Reorder   ENTER Launch   SPACE On/Off (SHIFT=All)   TAB Settings   Y Security   F Filter   / Search   ESC Exit',
			15);
		hintBar.setFormat(Paths.font("vcr.ttf"), 15, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		hintBar.alpha = 0.7;
		add(hintBar);

		// align right-aligned header labels
		searchTxt.x = FlxG.width - margin - 18 - filterWidthOf('FILTER: LAUNCHABLE') - 120 - searchTxt.width;
		filterTxt.x = FlxG.width - margin - 18 - filterTxt.width;

		// no-mods overlay
		if (modsList.all.length < 1) {
			noModsTxt = new FlxText(rightX, 0, rightW, Language.getPhrase('no_mods_installed', 'NO MODS INSTALLED\nPRESS BACK TO EXIT OR INSTALL A MOD'), 32);
			noModsTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			noModsTxt.borderSize = 2;
			noModsTxt.screenCenter(Y);
			add(noModsTxt);
		}

		// initial selection (respect startMod from a reload)
		applyView();
		if (startMod != null) {
			for (i in 0...view.length)
				if (view[i].folder == startMod) {
					curSel = i;
					break;
				}
		}
		layoutList();
		updateDetail();
		_lastControllerMode = controls.controllerMode;
		super.create();

		#if mobile
		addTouchPad('FULL', 'A_B');
		#end
	}

	inline function filterWidthOf(s:String):Float {
		var t = new FlxText(0, 0, 0, s, 22);
		t.setFormat(Paths.font("vcr.ttf"), 22);
		var w = t.width;
		t.destroy();
		return w;
	}

	function sectionHeader(x:Float, y:Float, label:String):FlxText {
		var t = new FlxText(x, y, 0, label, 20);
		t.setFormat(Paths.font("vcr.ttf"), 20, 0xFFFFD24A, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		t.borderSize = 1;
		add(t);
		return t;
	}

	function sectionBody(x:Float, y:Float, w:Float, h:Int):FlxText {
		var t = new FlxText(x, y, w, "", 18);
		t.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT);
		t.height = h;
		add(t);
		return t;
	}

	// ───────────────────────────────────────────────────────── update ──
	override function update(elapsed:Float) {
		if (Math.abs(FlxG.mouse.deltaX) > 10 || Math.abs(FlxG.mouse.deltaY) > 10) {
			controls.controllerMode = false;
			if (!FlxG.mouse.visible)
				FlxG.mouse.visible = true;
		}
		if (controls.controllerMode != _lastControllerMode) {
			if (controls.controllerMode)
				FlxG.mouse.visible = false;
			_lastControllerMode = controls.controllerMode;
		}

		// Search text entry takes priority over shortcuts.
		if (searching) {
			handleSearchInput();
			#if android
			if (controls.BACK) {
				endSearch();
				super.update(elapsed);
				return;
			}
			#end
			if (view.length > 0) {
				if (controls.UI_DOWN_P)
					changeSel(1);
				else if (controls.UI_UP_P)
					changeSel(-1);
			}
			super.update(elapsed);
			return;
		}

		// Header mouse clicks (Search / Filter).
		if (FlxG.mouse.justPressed && FlxG.mouse.visible) {
			if (FlxG.mouse.overlaps(searchTxt))
				beginSearch();
			else if (FlxG.mouse.overlaps(filterTxt))
				cycleFilter();
		}

		if (controls.BACK) {
			if (query.length > 0 || filterMode != 0) {
				// first BACK clears the filter/search, second leaves
				query = '';
				filterMode = 0;
				searchTxt.text = 'SEARCH';
				applyView();
				FlxG.sound.play(Paths.sound('cancelMenu'));
				return;
			}
			exitMenu();
			return;
		}

		if (modsList.all.length > 0 && view.length > 0) {
			var shiftMult:Int = (FlxG.keys.pressed.SHIFT
				|| FlxG.gamepads.anyPressed(LEFT_SHOULDER)
				|| FlxG.gamepads.anyPressed(RIGHT_SHOULDER)) ? 4 : 1;

			if (controls.UI_DOWN_P)
				changeSel(shiftMult);
			else if (controls.UI_UP_P)
				changeSel(-shiftMult);
			else if (FlxG.mouse.wheel != 0)
				changeSel(-FlxG.mouse.wheel * shiftMult);
			else if (controls.UI_UP || controls.UI_DOWN) {
				var last:Float = holdTime;
				holdTime += elapsed;
				if (holdTime > 0.5 && Math.floor(last * 8) != Math.floor(holdTime * 8))
					changeSel(shiftMult * (controls.UI_UP ? -1 : 1));
			} else
				holdTime = 0;

			// Mouse: click a row to select it.
			if (FlxG.mouse.justPressed && FlxG.mouse.visible) {
				for (vi in 0...view.length) {
					var item = view[vi];
					if (item.visible && FlxG.mouse.overlaps(item)) {
						if (curSel != vi) {
							curSel = vi;
							layoutList();
							updateDetail();
							FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
						}
						break;
					}
				}
			}

			// Reorder (only meaningful in the unfiltered/un-searched ALL view).
			if (filterMode == 0 && query.length == 0) {
				if (controls.UI_LEFT_P)
					moveSelected(-1);
				else if (controls.UI_RIGHT_P)
					moveSelected(1);
			}

			// Actions. Space/Y (toggle) is checked BEFORE Accept (launch): ACCEPT
			// is bound to both Enter AND Space, so otherwise Space would launch and
			// never toggle.
			if (FlxG.keys.justPressed.SPACE || FlxG.gamepads.anyJustPressed(Y)) {
				if (FlxG.keys.pressed.SHIFT)
					toggleAll();
				else
					toggleSelected();
			} else if (controls.ACCEPT)
				launchSelected();
			else if (!vsliceMode && (FlxG.keys.justPressed.TAB || FlxG.gamepads.anyJustPressed(X)))
				openSelectedSettings();
			else if (!vsliceMode && FlxG.keys.justPressed.Y)
				openSelectedSecurity();
			else if (FlxG.keys.justPressed.F)
				cycleFilter();
			else if (FlxG.keys.justPressed.SLASH)
				beginSearch();
		} else if (modsList.all.length < 1) {
			noModsSine += 180 * elapsed;
			if (noModsTxt != null)
				noModsTxt.alpha = 1 - Math.sin((Math.PI * noModsSine) / 180);

			nextAttempt -= elapsed;
			if (nextAttempt < 0) {
				nextAttempt = 1;
				if (vsliceMode)
					@:privateAccess Mods.updateVSliceModList();
				else
					@:privateAccess Mods.updateModList();
				modsList = vsliceMode ? Mods.parseVSliceList() : Mods.parseList();
				if (modsList.all.length > 0) {
					trace('mod(s) found! reloading');
					reload();
				}
			}
		}

		super.update(elapsed);
	}

	// ──────────────────────────────────────────────────── navigation ──
	inline function currentMod():ModItem
		return (curSel >= 0 && curSel < view.length) ? view[curSel] : null;

	function changeSel(add:Int) {
		if (view.length < 1)
			return;
		curSel += add;
		if (curSel < 0)
			curSel = 0;
		else if (curSel > view.length - 1)
			curSel = view.length - 1;
		layoutList();
		updateDetail();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	// Rebuilds `view` from the filter mode + search query.
	function applyView() {
		var prev = currentMod();
		view = [];
		var q = query.toLowerCase();
		for (item in modsGroup.members) {
			var enabled = !modsList.disabled.contains(item.folder);
			var passFilter = switch (filterMode) {
				case 1: enabled;
				case 2: !enabled;
				case 3: item.launchable;
				default: true;
			}
			if (!passFilter)
				continue;
			if (q.length > 0 && item.name.toLowerCase().indexOf(q) < 0 && item.folder.toLowerCase().indexOf(q) < 0)
				continue;
			view.push(item);
		}

		// keep the same mod selected if it's still visible
		curSel = 0;
		if (prev != null) {
			var idx = view.indexOf(prev);
			if (idx >= 0)
				curSel = idx;
		}
		if (curSel > view.length - 1)
			curSel = Std.int(Math.max(0, view.length - 1));

		filterTxt.text = 'FILTER: ' + FILTERS[filterMode];
		layoutList();
		updateDetail();
	}

	// Positions the visible rows top-anchored, scrolling only to keep the
	// selection on screen.
	function layoutList() {
		var rows = Std.int(listH / rowH);

		if (curSel < scrollOffset)
			scrollOffset = curSel;
		else if (curSel >= scrollOffset + rows)
			scrollOffset = curSel - rows + 1;
		if (scrollOffset > view.length - rows)
			scrollOffset = view.length - rows;
		if (scrollOffset < 0)
			scrollOffset = 0;

		for (item in modsGroup.members)
			item.visible = false;

		for (vi in 0...view.length) {
			var item = view[vi];
			var slot = vi - scrollOffset;
			item.visible = (slot >= 0 && slot < rows);
			item.x = listX + 6;
			item.y = listY + 6 + slot * rowH;
			item.alpha = (vi == curSel) ? 1 : 0.55;
			item.selectBg.visible = (vi == curSel && item.visible);

			var enabled = !modsList.disabled.contains(item.folder);
			item.icon.color = enabled ? FlxColor.WHITE : 0xFFFF6666;
			item.text.color = enabled ? FlxColor.WHITE : FlxColor.GRAY;
		}
	}

	function updateDetail() {
		var m = currentMod();
		if (m == null) {
			modName.text = '';
			modLogo.visible = false;
			descTxt.text = featTxt.text = clTxt.text = '';
			descHeader.visible = featHeader.visible = clHeader.visible = false;
			descTxt.visible = featTxt.visible = clTxt.visible = false;
			launchStatus.text = '';
			bannerImg.visible = false;
			launchBtn.enabled = settingsBtn.enabled = false;
			return;
		}

		FlxTween.cancelTweensOf(bg);
		FlxTween.color(bg, 0.5, bg.color, m.bgColor);

		bannerImg.clipRect = null;
		if (m.bannerPath != null) {
			// Mods live on disk, not in the OpenFL asset manifest, so load the
			// file directly (cached per-mod so we don't re-read it every scroll).
			if (m.bannerGraphic == null)
				m.bannerGraphic = Paths.cacheBitmap(m.bannerPath, #if mobile mobile.backend.AssetUtil.getBitmap(m.bannerPath) #else BitmapData.fromFile(m.bannerPath) #end);
			bannerImg.loadGraphic(m.bannerGraphic);

			// Cover the whole panel, then clip the overflow to the panel rect.
			var fw = bannerImg.frameWidth, fh = bannerImg.frameHeight;
			var sc = Math.max(bgBanner.width / fw, bgBanner.height / fh);
			bannerImg.setGraphicSize(Std.int(fw * sc), Std.int(fh * sc));
			bannerImg.updateHitbox();

			var cw = bgBanner.width / sc, ch = bgBanner.height / sc;
			var crx = (fw - cw) / 2, cry = (fh - ch) / 2;
			bannerImg.clipRect = new flixel.math.FlxRect(crx, cry, cw, ch);
			bannerImg.x = bgBanner.x - crx * sc;
			bannerImg.y = bgBanner.y - cry * sc;
		} else {
			// No banner art: show the (square) pack icon centred, not stretched.
			bannerImg.loadGraphic(m.icon.graphic, true, 150, 150);
			if (m.totalFrames > 0) {
				bannerImg.animation.add('b', [for (i in 0...m.totalFrames) i], m.iconFps);
				bannerImg.animation.play('b');
			}
			var sc = (bgBanner.height - 70) / 150;
			bannerImg.setGraphicSize(Std.int(150 * sc), Std.int(150 * sc));
			bannerImg.updateHitbox();
			bannerImg.x = bgBanner.x + (bgBanner.width - bannerImg.width) / 2;
			bannerImg.y = bgBanner.y + 12;
		}
		bannerImg.antialiasing = m.icon.antialiasing;
		bannerImg.visible = true;

		// Logo (logo.png) replaces the mod-name text when present.
		if (m.logoPath != null) {
			if (m.logoGraphic == null)
				m.logoGraphic = Paths.cacheBitmap(m.logoPath, #if mobile mobile.backend.AssetUtil.getBitmap(m.logoPath) #else BitmapData.fromFile(m.logoPath) #end);
			modLogo.loadGraphic(m.logoGraphic);
			var sc = Math.min(64 / modLogo.frameHeight, (bgBanner.width - 36) / modLogo.frameWidth);
			modLogo.setGraphicSize(Std.int(modLogo.frameWidth * sc), Std.int(modLogo.frameHeight * sc));
			modLogo.updateHitbox();
			modLogo.x = bgBanner.x + 18;
			modLogo.y = bgBanner.y + bgBanner.height - modLogo.height - 12;
			modLogo.visible = true;
			modName.text = '';
		} else {
			modLogo.visible = false;
			if (modName.scaleX != 0.9)
				modName.setScale(0.9);
			modName.text = m.name;
			var newScale = Math.min((bgBanner.width - 40) / (modName.width / 0.9), 0.9);
			modName.setScale(newScale);
			modName.x = bgBanner.x + 18;
			modName.y = bgBanner.y + bgBanner.height - modName.height - 14;
		}

		// Content sections, reflowed top-down; empty Features/Changelog are hidden.
		var cy:Float = contentTopY;
		descHeader.visible = descTxt.visible = true;
		descHeader.y = cy;
		cy += 28;
		descTxt.text = trimTo(m.desc + (m.vsliceMode ? m.getVSliceDetails() : ''), 320);
		descTxt.y = cy;
		cy += descTxt.height + 16;

		var hasFeat = m.features != null && m.features.length > 0;
		featHeader.visible = featTxt.visible = hasFeat;
		if (hasFeat) {
			featHeader.y = cy;
			cy += 28;
			featTxt.text = trimTo(m.features, 260);
			featTxt.y = cy;
			cy += featTxt.height + 16;
		}

		var hasCl = m.changelog != null && m.changelog.length > 0;
		clHeader.visible = clTxt.visible = hasCl;
		if (hasCl) {
			clHeader.y = cy;
			cy += 28;
			clTxt.text = trimTo(m.changelog, 360);
			clTxt.y = cy;
		}
		modRestartText.visible = m.mustRestart;

		var enabled = !modsList.disabled.contains(m.folder);
		enableBtn.setText(enabled ? Language.getPhrase('disable_button', 'DISABLE') : Language.getPhrase('enable_button', 'ENABLE'));
		settingsBtn.enabled = (m.settings != null && m.settings.length > 0);
		launchBtn.enabled = !vsliceMode && enabled && m.launchable;

		updateLaunchStatus(m, enabled);
	}

	function updateLaunchStatus(m:ModItem, enabled:Bool) {
		#if HSCRIPT_ALLOWED
		if (vsliceMode) {
			launchStatus.text = 'VSlice mod list';
			launchStatus.color = FlxColor.GRAY;
		} else if (!enabled) {
			launchStatus.text = 'Disabled - enable to launch';
			launchStatus.color = FlxColor.GRAY;
		} else if (m.launchable) {
			launchStatus.text = '> Press ENTER to Launch';
			launchStatus.color = 0xFF66FF66;
		} else {
			launchStatus.text = 'No launchable states';
			launchStatus.color = FlxColor.GRAY;
		}
		#else
		launchStatus.text = '';
		#end
	}

	inline function trimTo(s:String, n:Int):String
		return (s != null && s.length > n) ? s.substr(0, n) + '...' : (s != null ? s : '');

	// ───────────────────────────────────────────────────── actions ──
	function launchSelected() {
		#if (HSCRIPT_ALLOWED && MODS_ALLOWED && !mobile)
		var m = currentMod();
		if (m == null)
			return;
		if (vsliceMode || modsList.disabled.contains(m.folder) || !Mods.isLaunchable(m.folder)) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		}
		saveTxt();
		FlxG.sound.play(Paths.sound('confirmMenu'));
		persistentUpdate = false;
		FlxG.mouse.visible = false;
		FlxG.autoPause = ClientPrefs.data.autoPause;
		Mods.currentModDirectory = m.folder;
		Mods.pushGlobalMods();
		MusicBeatState.switchState(ScriptableState.tryCreate(Mods.getLaunchState(m.folder), new MainMenuState()));
		#else
		FlxG.sound.play(Paths.sound('cancelMenu'));
		#end
	}

	function toggleSelected() {
		var m = currentMod();
		if (m == null)
			return;
		var mod = m.folder;
		if (!modsList.disabled.contains(mod)) {
			modsList.enabled.remove(mod);
			modsList.disabled.push(mod);
		} else {
			modsList.disabled.remove(mod);
			modsList.enabled.push(mod);
		}
		if (m.mustRestart)
			waitingToRestart = true;
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		applyView();
	}

	function openSelectedSettings() {
		var m = currentMod();
		if (m != null && m.settings != null && m.settings.length > 0)
			openSubState(new ModSettingsSubState(m.settings, m.folder, m.name));
		else
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
	}

	function openSelectedSecurity() {
		var m = currentMod();
		if (m == null)
			return;
		// Reachable per-pack regardless of findings: lets users proactively
		// trust/block a mod's scripts. Only the master toggle gates it.
		if (!ClientPrefs.data.modSecurityEnabled) {
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
			launchStatus.text = 'Mod Security is disabled (enable it in Options)';
			launchStatus.color = FlxColor.YELLOW;
			return;
		}
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
		openSubState(new substates.ModSecuritySubstate([m.folder]));
	}

	// Bulk toggle over the current view: if anything visible is disabled, enable
	// all; otherwise disable all. Composes with filters/search (e.g. filter to
	// DISABLED then bulk-enable). Restart-flagging mirrors toggleSelected.
	function toggleAll() {
		if (view.length < 1)
			return;

		var anyDisabled:Bool = false;
		for (item in view)
			if (modsList.disabled.contains(item.folder)) {
				anyDisabled = true;
				break;
			}

		for (item in view) {
			var mod = item.folder;
			var isDisabled = modsList.disabled.contains(mod);
			if (anyDisabled && isDisabled) {
				modsList.disabled.remove(mod);
				modsList.enabled.push(mod);
				if (item.mustRestart)
					waitingToRestart = true;
			} else if (!anyDisabled && !isDisabled) {
				modsList.enabled.remove(mod);
				modsList.disabled.push(mod);
				if (item.mustRestart)
					waitingToRestart = true;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		applyView();
	}

	function cycleFilter() {
		filterMode = (filterMode + 1) % FILTERS.length;
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		applyView();
	}

	function beginSearch() {
		searching = true;
		searchTxt.text = 'SEARCH: ' + query + '_';
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		#if android
		mobile.backend.SoftKeyboard.open(searchType, searchBackspace, endSearch);
		#end
	}

	function endSearch() {
		searching = false;
		searchTxt.text = query.length > 0 ? 'SEARCH: ' + query : 'SEARCH';
		#if android mobile.backend.SoftKeyboard.close(); #end
	}

	#if android
	function searchType(input:String) {
		query += input.toLowerCase();
		searchTxt.text = 'SEARCH: ' + query + '_';
		applyView();
	}

	function searchBackspace() {
		if (query.length > 0) {
			query = query.substr(0, query.length - 1);
			searchTxt.text = 'SEARCH: ' + query + '_';
			applyView();
		}
	}
	#end

	function handleSearchInput() {
		var k:Int = FlxG.keys.firstJustPressed();
		if (k <= 0)
			return;
		if (k == 13 || k == 27) { // enter / escape
			endSearch();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			return;
		}
		if (k == 8) // backspace
			query = query.length > 0 ? query.substr(0, query.length - 1) : '';
		else if (k == 32)
			query += ' ';
		else if ((k >= 65 && k <= 90) || (k >= 48 && k <= 57))
			query += String.fromCharCode(k).toLowerCase();
		else
			return;

		searchTxt.text = 'SEARCH: ' + query + '_';
		applyView();
	}

	function moveSelected(dir:Int) {
		var m = currentMod();
		if (m == null)
			return;
		var from = modsList.all.indexOf(m.folder);
		var to = from + dir;
		if (to < 0)
			to = modsList.all.length - 1;
		else if (to >= modsList.all.length)
			to = 0;
		if (to == from)
			return;

		var other = modsGroup.members[to];
		if (m.mustRestart || (other != null && other.mustRestart))
			waitingToRestart = true;

		modsGroup.remove(m, true);
		modsList.all.remove(m.folder);
		modsGroup.insert(to, m);
		modsList.all.insert(to, m.folder);

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		applyView();
	}

	function reload() {
		saveTxt();
		FlxG.autoPause = ClientPrefs.data.autoPause;
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		var m = currentMod();
		MusicBeatState.switchState(new ModsMenuState(m != null ? m.folder : null, vsliceMode, returnToSelector));
	}

	function exitMenu() {
		saveTxt();
		FlxG.sound.play(Paths.sound('cancelMenu'));
		if (returnToSelector) {
			MusicBeatState.switchState(new ModsManagerSelectorState());
		} else if (waitingToRestart) {
			TitleState.initialized = false;
			TitleState.closedState = false;
			FlxG.sound.music.fadeOut(0.3);
			if (FreeplayState.vocals != null) {
				FreeplayState.vocals.fadeOut(0.3);
				FreeplayState.vocals = null;
			}
			FlxG.camera.fade(FlxColor.BLACK, 0.5, false, FlxG.resetGame, false);
		} else {
			MusicBeatState.switchState(ScriptableState.tryCreate('MainMenuState', new MainMenuState()));
		}

		persistentUpdate = false;
		FlxG.autoPause = ClientPrefs.data.autoPause;
		FlxG.mouse.visible = false;
	}

	function saveTxt() {
		Mods.saveList(modsList, vsliceMode);
		if (vsliceMode)
		{
			Mods.parseVSliceList();
			Mods.loadTopVSliceMod();
		}
		else
		{
			Mods.parseList();
			Mods.loadTopMod();
		}
	}
}

class ModItem extends FlxSpriteGroup {
	public var selectBg:FlxSprite;
	public var icon:FlxSprite;
	public var text:FlxText;
	public var totalFrames:Int = 0;

	// options
	public var name:String = 'Unknown Mod';
	public var desc:String = 'No description provided.';
	public var iconFps:Int = 10;
	public var bgColor:FlxColor = 0xFF665AFF;
	public var pack:Dynamic = null;
	public var folder:String = 'unknownMod';
	public var mustRestart:Bool = false;
	public var settings:Array<Dynamic> = null;
	public var vsliceMode:Bool = false;

	// Mod-browser content. Banner = banner.png (else the animated pack icon).
	// Features = features.txt or pack.json "features". Changelog = changelog.txt
	// or pack.json "changelog". All optional with graceful fallbacks.
	public var bannerPath:String = null;
	public var bannerGraphic:FlxGraphic = null;
	public var logoPath:String = null; // logo.png, shown instead of the name text
	public var logoGraphic:FlxGraphic = null;
	public var features:String = '';
	public var changelog:String = '';
	public var launchable:Bool = false;

	public function new(folder:String, vsliceMode:Bool = false) {
		super();

		this.folder = folder;
		this.vsliceMode = vsliceMode;
		pack = vsliceMode ? getVSliceMeta(folder) : Mods.getPack(folder);

		var path:String = Paths.mods('$folder/data/settings.json');
		if (!vsliceMode && FileSystem.exists(path)) {
			try {
				settings = cast tjson.TJSON.parse(File.getContent(path));
			} catch (e:Dynamic) {
				var errorTitle = 'Mod name: ' + Mods.currentModDirectory;
				var errorMsg = 'An error occurred: $e';
				#if windows
				lime.app.Application.current.window.alert(errorMsg, errorTitle);
				#end
				trace('$errorTitle - $errorMsg');
			}
		}

		selectBg = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		selectBg.alpha = 0.8;
		selectBg.visible = false;
		add(selectBg);

		icon = new FlxSprite(5, 5);
		icon.antialiasing = ClientPrefs.data.antialiasing;
		add(icon);

		text = new FlxText(95, 38, 230, "", 16);
		text.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.borderSize = 2;
		text.y -= Std.int(text.height / 2);
		add(text);

		var isPixel = false;
		var file:String = vsliceMode ? Paths.vsliceMods('$folder/_polymod_icon.png') : Paths.mods('$folder/pack.png');
		if (!FileSystem.exists(file)) {
			file = vsliceMode ? Paths.vsliceMods('$folder/pack-pixel.png') : Paths.mods('$folder/pack-pixel.png');
			isPixel = true;
		}

		var bmp:BitmapData = null;
		if (FileSystem.exists(file))
			bmp = #if mobile mobile.backend.AssetUtil.getBitmap(file) #else BitmapData.fromFile(file) #end;
		else
			isPixel = false;

		if (FileSystem.exists(file)) {
			if (vsliceMode) {
				icon.loadGraphic(Paths.cacheBitmap(file, bmp));
				icon.setGraphicSize(75, 75);
				icon.updateHitbox();
			} else {
				icon.loadGraphic(Paths.cacheBitmap(file, bmp), true, 150, 150);
				if (isPixel)
					icon.antialiasing = false;
			}
		} else
			icon.loadGraphic(Paths.image('unknownMod'), true, 150, 150);
		if (!vsliceMode) {
			icon.scale.set(0.5, 0.5);
			icon.updateHitbox();
		}

		this.name = folder;
		if (pack != null) {
			if (pack.name != null)
				this.name = pack.name;
			if (pack.title != null)
				this.name = pack.title;
			if (pack.description != null)
				this.desc = pack.description;
			if (pack.iconFramerate != null)
				this.iconFps = pack.iconFramerate;
			if (pack.color != null) {
				this.bgColor = FlxColor.fromRGB(pack.color[0] != null ? pack.color[0] : 170, pack.color[1] != null ? pack.color[1] : 0,
					pack.color[2] != null ? pack.color[2] : 255);
			}
			this.mustRestart = (pack.restart == true);
		}
		text.text = this.name;

		// Banner: banner.png only; otherwise the detail panel uses the icon.
		var bannerFile:String = vsliceMode ? Paths.vsliceMods('$folder/banner.png') : Paths.mods('$folder/banner.png');
		bannerPath = FileSystem.exists(bannerFile) ? bannerFile : null;

		// Logo: logo.png replaces the mod-name text in the banner if present.
		var logoFile:String = vsliceMode ? Paths.vsliceMods('$folder/logo.png') : Paths.mods('$folder/logo.png');
		logoPath = FileSystem.exists(logoFile) ? logoFile : null;

		// Features: features.txt, else pack.json "features" (array or string).
		var featFile:String = vsliceMode ? Paths.vsliceMods('$folder/features.txt') : Paths.mods('$folder/features.txt');
		if (FileSystem.exists(featFile))
			features = File.getContent(featFile);
		else if (pack != null && pack.features != null)
			features = (pack.features is Array) ? (cast(pack.features, Array<Dynamic>)).join('\n') : Std.string(pack.features);

		// Changelog: changelog.txt, else pack.json "changelog".
		var clFile:String = vsliceMode ? Paths.vsliceMods('$folder/changelog.txt') : Paths.mods('$folder/changelog.txt');
		if (FileSystem.exists(clFile))
			changelog = File.getContent(clFile);
		else if (pack != null && pack.changelog != null)
			changelog = (pack.changelog is Array) ? (cast(pack.changelog, Array<Dynamic>)).join('\n') : Std.string(pack.changelog);

		#if HSCRIPT_ALLOWED
		launchable = !vsliceMode && Mods.isLaunchable(folder);
		#end

		if (bmp != null && !vsliceMode) {
			totalFrames = Math.floor(bmp.width / 150) * Math.floor(bmp.height / 150);
			icon.animation.add("icon", [for (i in 0...totalFrames) i], iconFps);
			icon.animation.play("icon");
		}
		selectBg.scale.set(width + 5, height + 5);
		selectBg.updateHitbox();
	}

	function getVSliceMeta(folder:String):Dynamic
	{
		var metaPath:String = Paths.vsliceMods('$folder/_polymod_meta.json');
		if (FileSystem.exists(metaPath))
		{
			try
			{
				return Json.parse(File.getContent(metaPath));
			}
			catch (e:Dynamic)
			{
				trace('[ModsMenuState] Failed to parse _polymod_meta.json for $folder: $e');
			}
		}
		return null;
	}

	public function getVSliceDetails():String
	{
		if (!vsliceMode || pack == null)
			return '';

		var lines:Array<String> = [];
		addMetaLine(lines, 'Version', ['mod_version', 'modVersion', 'version']);
		addMetaLine(lines, 'API', ['api_version', 'apiVersion', 'api']);
		addMetaLine(lines, 'License', ['license']);

		var contributors:String = getContributorsSummary();
		if (contributors.length > 0)
			lines.push('Contributors: ' + contributors);

		return lines.length > 0 ? '\n\n' + lines.join('\n') : '';
	}

	function addMetaLine(lines:Array<String>, label:String, fields:Array<String>):Void
	{
		for (field in fields)
		{
			var value:Dynamic = Reflect.field(pack, field);
			if (value == null)
				continue;

			var text:String = Std.string(value).trim();
			if (text.length > 0)
			{
				lines.push(label + ': ' + text);
				return;
			}
		}
	}

	function getContributorsSummary():String
	{
		var contributors:Dynamic = Reflect.field(pack, 'contributors');
		if (contributors == null)
			contributors = Reflect.field(pack, 'authors');
		if (contributors == null)
			contributors = Reflect.field(pack, 'author');
		if (contributors == null)
			return '';

		if (Std.isOfType(contributors, Array))
		{
			var names:Array<String> = [];
			for (entry in cast(contributors, Array<Dynamic>))
			{
				var name:String = null;
				if (Std.isOfType(entry, String))
					name = Std.string(entry);
				else if (entry != null)
				{
					var raw:Dynamic = Reflect.field(entry, 'name');
					if (raw == null)
						raw = Reflect.field(entry, 'username');
					if (raw != null)
						name = Std.string(raw);
				}
				if (name != null && name.trim().length > 0)
					names.push(name.trim());
			}
			return names.join(', ');
		}

		var text:String = Std.string(contributors).trim();
		return text;
	}
}

class MenuButton extends FlxSpriteGroup {
	public var bg:FlxSprite;
	public var textOn:Alphabet;
	public var textOff:Alphabet;
	public var icon:FlxSprite;
	public var onClick:Void->Void = null;
	public var enabled(default, set):Bool = true;

	public function new(x:Float, y:Float, width:Int, height:Int, ?text:String = null, ?img:FlxGraphic = null, onClick:Void->Void = null, animWidth:Int = 0,
			animHeight:Int = 0) {
		super(x, y);

		bg = FlxSpriteUtil.drawRoundRect(new FlxSprite().makeGraphic(width, height, FlxColor.TRANSPARENT), 0, 0, width, height, 15, 15, FlxColor.WHITE);
		bg.color = FlxColor.BLACK;
		add(bg);

		if (text != null) {
			textOn = new Alphabet(0, 0, "", false);
			textOn.setScale(0.6);
			textOn.text = text;
			textOn.alpha = 0.6;
			textOn.visible = false;
			centerOnBg(textOn);
			textOn.y -= 30;
			add(textOn);

			textOff = new Alphabet(0, 0, "", true);
			textOff.setScale(0.52);
			textOff.text = text;
			textOff.alpha = 0.6;
			centerOnBg(textOff);
			add(textOff);
		} else if (img != null) {
			icon = new FlxSprite();
			if (animWidth > 0 || animHeight > 0)
				icon.loadGraphic(img, true, animWidth, animHeight);
			else
				icon.loadGraphic(img);
			centerOnBg(icon);
			add(icon);
		}

		this.onClick = onClick;
		setButtonVisibility(false);
	}

	// Updates a text button's label (used for the Enable/Disable toggle).
	// Unlike centerOnBg (which assumes a not-yet-added child), this runs after
	// the button is on screen, so it must centre against bg's WORLD position and
	// re-assert the label scale (set_text rebuilds the letters).
	public function setText(t:String) {
		if (textOff != null) {
			textOff.text = t;
			textOff.setScale(0.52);
			textOff.x = bg.x + bg.width / 2 - textOff.width / 2;
			textOff.y = bg.y + bg.height / 2 - textOff.height / 2;
		}
		if (textOn != null) {
			textOn.text = t;
			textOn.setScale(0.6);
			textOn.x = bg.x + bg.width / 2 - textOn.width / 2;
			textOn.y = bg.y + bg.height / 2 - textOn.height / 2 - 30;
		}
	}

	public var focusChangeCallback:Bool->Void = null;
	public var onFocus(default, set):Bool = false;
	public var ignoreCheck:Bool = false;

	private var _needACheck:Bool = false;

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (!enabled) {
			onFocus = false;
			return;
		}

		if (!ignoreCheck
			&& !Controls.instance.controllerMode
			&& (FlxG.mouse.justPressed || FlxG.mouse.justMoved)
			&& FlxG.mouse.visible)
			onFocus = FlxG.mouse.overlaps(this);

		if (onFocus && onClick != null && FlxG.mouse.justPressed)
			onClick();

		if (_needACheck) {
			_needACheck = false;
			if (!Controls.instance.controllerMode)
				setButtonVisibility(FlxG.mouse.overlaps(this));
		}
	}

	function set_onFocus(newValue:Bool) {
		var lastFocus:Bool = onFocus;
		onFocus = newValue;
		if (onFocus != lastFocus && enabled)
			setButtonVisibility(onFocus);
		return newValue;
	}

	function set_enabled(newValue:Bool) {
		enabled = newValue;
		setButtonVisibility(false);
		alpha = enabled ? 1 : 0.4;

		_needACheck = enabled;
		return newValue;
	}

	public function setButtonVisibility(focusVal:Bool) {
		alpha = 1;
		bg.color = focusVal ? FlxColor.WHITE : FlxColor.BLACK;
		bg.alpha = focusVal ? 0.8 : 0.6;

		var focusAlpha = focusVal ? 1 : 0.6;
		if (textOn != null && textOff != null) {
			textOn.alpha = textOff.alpha = focusAlpha;
			textOn.visible = focusVal;
			textOff.visible = !focusVal;
		} else if (icon != null) {
			icon.alpha = focusAlpha;
			icon.color = focusVal ? FlxColor.BLACK : FlxColor.WHITE;
		}

		if (!enabled)
			alpha = 0.4;
		if (focusChangeCallback != null)
			focusChangeCallback(focusVal);
	}

	public function centerOnBg(spr:FlxSprite) {
		spr.x = bg.width / 2 - spr.width / 2;
		spr.y = bg.height / 2 - spr.height / 2;
	}
}

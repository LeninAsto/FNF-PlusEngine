package states;

import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import flixel.text.FlxText;
import openfl.display.BitmapData;
#if mobile
import mobile.backend.MobileScaleMode;
#end

enum MainMenuColumn
{
	LEFT;
	CENTER;
	RIGHT;
}

class MainMenuState extends MusicBeatState
{
	public static var fnfApiVersion:String = '0.8.5';
	public static var plusEngineVersion:String = '1.3-prerelease'; // Nothing interesting =)
	public static var psychEngineVersion:String = "1.0.4 (" + plusEngineVersion + ")"; // This is also used for Discord RPC
	public static var curSelected:Int = 0;
	public static var curColumn:MainMenuColumn = CENTER;

	public var allowMouse:Bool = true; // Turn this off to block mouse movement in menus

	public var menuItems:PlusMainMenuItemGroup;
	public var leftWatermarkText:FlxText;
	public var leftItem:FlxSprite;
	public var rightItem:FlxSprite;

	inline function safeX(x:Float):Float
	{
		#if mobile
		return MobileScaleMode.getHorizontalOffset() + x;
		#else
		return x;
		#end
	}

	inline function safeWidth():Float
	{
		#if mobile
		return MobileScaleMode.getSafeWidth();
		#else
		return FlxG.width;
		#end
	}

	// Centered/Text options
	public var optionShit:Array<String> = ['story_mode', 'freeplay', #if MODS_ALLOWED 'mods', #end 'credits'];

	public var leftOption:String = #if ACHIEVEMENTS_ALLOWED 'achievements' #else null #end;
	public var rightOption:String = 'options';

	public var magenta:FlxSprite;
	public var camFollow:FlxObject;

	static var showOutdatedWarning:Bool = true;
	static var updateWarningShown:Bool = false;

	override function create()
	{
		super.create();

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = 0.25;
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		menuItems = new PlusMainMenuItemGroup();
		add(menuItems);

		for (num => option in optionShit)
		{
			var item:FlxSprite = createMenuItem(option, 0, (num * 140) + 90);
			item.y += (4 - optionShit.length) * 70; // Offsets for when you have anything other than 4 items
			item.screenCenter(X);
		}

		if (leftOption != null)
			leftItem = createMenuItem(leftOption, safeX(60), 490);
		if (rightOption != null)
		{
			rightItem = createMenuItem(rightOption, safeX(safeWidth() - 60), 490);
			rightItem.x -= rightItem.width;
		}

		var buildLine:String = BuildInfo.versionLine();
		var hasBuildLine:Bool = buildLine.length > 0;
		var psychVer:FlxText = new FlxText(safeX(12), FlxG.height - (hasBuildLine ? 64 : 44), 0, "Psych Engine v" + psychEngineVersion, 12);
		psychVer.scrollFactor.set();
		psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);
		var fnfVer:FlxText = new FlxText(safeX(12), FlxG.height - (hasBuildLine ? 44 : 24), 0, "FNF API v" + fnfApiVersion, 12);
		fnfVer.scrollFactor.set();
		fnfVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		leftWatermarkText = fnfVer;
		add(fnfVer);
		if (hasBuildLine)
		{
			var buildVer:FlxText = new FlxText(safeX(12), FlxG.height - 24, 0, buildLine, 12);
			buildVer.scrollFactor.set();
			buildVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			add(buildVer);
		}
		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		#if CHECK_FOR_UPDATES
		tryShowOutdatedWarning();
		#end
		#if MODS_ALLOWED
		tryShowModSecurityWarning();
		#end

		FlxG.camera.follow(camFollow, null, 0.15);

		addTouchPad('NONE', 'E_X');

		#if vslice
		funkin.plus.VSlicePlusStateBridge.create(this);
		#end
	}

	#if MODS_ALLOWED
	function tryShowModSecurityWarning():Void
	{
		if (selectedSomethin || subState != null)
			return;

		var pending:Array<String> = backend.ModSecurity.getPendingMods();
		if (pending.length < 1)
			return;

		persistentUpdate = false;
		openSubState(backend.ScriptableSubstate.tryCreate('ModSecuritySubstate', new substates.ModSecuritySubstate(pending)));
	}
	#end

	#if CHECK_FOR_UPDATES
	function tryShowOutdatedWarning():Void
	{
		if (!showOutdatedWarning || !ClientPrefs.data.checkForUpdates || updateWarningShown || selectedSomethin)
			return;

		if (CoolUtil.hasUpdate && CoolUtil.latestVersion != plusEngineVersion)
		{
			substates.OutdatedSubState.updateVersion = CoolUtil.latestVersion;
			persistentUpdate = false;
			updateWarningShown = true;
			openSubState(backend.ScriptableSubstate.tryCreate('OutdatedSubState', new substates.OutdatedSubState()));
		}
	}
	#end

	function createMenuItem(name:String, x:Float, y:Float):FlxSprite
	{
		var menuItem:FlxSprite = new FlxSprite(x, y);
		try
		{
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_$name');
		}
		catch (e:Dynamic)
		{
			trace('Main menu atlas failed for $name, trying direct disk atlas: $e');
			menuItem.frames = loadMenuAtlasFromDisk(name);
		}

		if (menuItem.frames != null)
		{
			menuItem.animation.addByPrefix('idle', '$name idle', 24, true);
			menuItem.animation.addByPrefix('selected', '$name selected', 24, true);
			menuItem.animation.play('idle');
		}
		else
		{
			var fallbackBitmap:Null<BitmapData> = loadMenuBitmapFromDisk(name);
			if (fallbackBitmap != null)
			{
				menuItem.loadGraphic(fallbackBitmap);
			}
			else
			{
				trace('Main menu image missing for $name; using transparent placeholder.');
				menuItem.makeGraphic(360, 80, FlxColor.TRANSPARENT);
			}
		}
		menuItem.updateHitbox();

		menuItem.antialiasing = ClientPrefs.data.antialiasing;
		menuItem.scrollFactor.set();
		menuItems.add(menuItem);
		return menuItem;
	}

	function loadMenuAtlasFromDisk(name:String):Null<FlxAtlasFrames>
	{
		var base:String = 'assets/shared/images/mainmenu/menu_$name';
		var png:String = '$base.png';
		var xml:String = '$base.xml';

		if (!FileSystem.exists(png) || !FileSystem.exists(xml))
			return null;

		try
		{
			var bitmap:BitmapData = BitmapData.fromFile(png);
			if (bitmap == null)
				return null;
			return FlxAtlasFrames.fromSparrow(bitmap, File.getContent(xml));
		}
		catch (e:Dynamic)
		{
			trace('Direct main menu atlas failed for $name: $e');
		}

		return null;
	}

	function loadMenuBitmapFromDisk(name:String):Null<BitmapData>
	{
		var png:String = 'assets/shared/images/mainmenu/menu_$name.png';
		if (!FileSystem.exists(png))
			return null;

		try
		{
			return BitmapData.fromFile(png);
		}
		catch (e:Dynamic)
		{
			trace('Direct main menu image failed for $name: $e');
		}

		return null;
	}

	var selectedSomethin:Bool = false;

	var timeNotMoving:Float = 0;

	override function update(elapsed:Float)
	{
		#if vslice
		funkin.plus.VSlicePlusStateBridge.update(elapsed, true);
		#end

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);

		#if CHECK_FOR_UPDATES
		tryShowOutdatedWarning();
		#end

		if (!selectedSomethin && !isMenuInputBlocked())
		{
			if (controls.UI_UP_P)
				changeItem(-1);

			if (controls.UI_DOWN_P)
				changeItem(1);

			var allowMouse:Bool = allowMouse;
			if (allowMouse
				&& ((FlxG.mouse.deltaScreenX != 0 && FlxG.mouse.deltaScreenY != 0)
					|| FlxG.mouse.justPressed)) // FlxG.mouse.deltaScreenX/Y checks is more accurate than FlxG.mouse.justMoved
			{
				allowMouse = false;
				FlxG.mouse.visible = true;
				timeNotMoving = 0;

				var selectedItem:FlxSprite;
				switch (curColumn)
				{
					case CENTER:
						selectedItem = menuItems.members[curSelected];
					case LEFT:
						selectedItem = leftItem;
					case RIGHT:
						selectedItem = rightItem;
				}

				if (leftItem != null && FlxG.mouse.overlaps(leftItem))
				{
					allowMouse = true;
					if (selectedItem != leftItem)
					{
						curColumn = LEFT;
						changeItem();
					}
				}
				else if (rightItem != null && FlxG.mouse.overlaps(rightItem))
				{
					allowMouse = true;
					if (selectedItem != rightItem)
					{
						curColumn = RIGHT;
						changeItem();
					}
				}
				else
				{
					var dist:Float = -1;
					var distItem:Int = -1;
					for (i in 0...optionShit.length)
					{
						var memb:FlxSprite = menuItems.members[i];
						if (FlxG.mouse.overlaps(memb))
						{
							var distance:Float = Math.sqrt(Math.pow(memb.getGraphicMidpoint().x - FlxG.mouse.screenX, 2)
								+ Math.pow(memb.getGraphicMidpoint().y - FlxG.mouse.screenY, 2));
							if (dist < 0 || distance < dist)
							{
								dist = distance;
								distItem = i;
								allowMouse = true;
							}
						}
					}

					if (distItem != -1 && selectedItem != menuItems.members[distItem])
					{
						curColumn = CENTER;
						curSelected = distItem;
						changeItem();
					}
				}
			}
			else
			{
				timeNotMoving += elapsed;
				if (timeNotMoving > 2)
					FlxG.mouse.visible = false;
			}

			switch (curColumn)
			{
				case CENTER:
					if (controls.UI_LEFT_P && leftOption != null)
					{
						curColumn = LEFT;
						changeItem();
					}
					else if (controls.UI_RIGHT_P && rightOption != null)
					{
						curColumn = RIGHT;
						changeItem();
					}

				case LEFT:
					if (controls.UI_RIGHT_P)
					{
						curColumn = CENTER;
						changeItem();
					}

				case RIGHT:
					if (controls.UI_LEFT_P)
					{
						curColumn = CENTER;
						changeItem();
					}
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(backend.ScriptableState.tryCreate('TitleState', new TitleState()));
			}

			if (controls.ACCEPT || (FlxG.mouse.overlaps(menuItems, FlxG.camera) && FlxG.mouse.justPressed && allowMouse))
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				selectedSomethin = true;
				FlxG.mouse.visible = false;

				if (ClientPrefs.data.flashing)
					FlxFlicker.flicker(magenta, 1.1, 0.15, false);

				var item:FlxSprite;
				var option:String;
				switch (curColumn)
				{
					case CENTER:
						option = optionShit[curSelected];
						item = menuItems.members[curSelected];

					case LEFT:
						option = leftOption;
						item = leftItem;

					case RIGHT:
						option = rightOption;
						item = rightItem;
				}

				FlxFlicker.flicker(item, 1, 0.06, false, false, function(flick:FlxFlicker)
				{
					switch (option)
					{
						case 'story_mode':
							#if FEATURE_POLYMOD_MODS
							if (funkin.plus.VSliceRuntime.shouldUseVSliceRuntime())
							{
								MusicBeatState.switchState(funkin.plus.VSliceRuntime.createStoryMenuState());
								return;
							}
							#end
							MusicBeatState.switchState(backend.ScriptableState.tryCreate('StoryMenuState', new StoryMenuState()));
						case 'freeplay':
							MusicBeatState.switchState(FreeplayStateSelector.create());

						#if MODS_ALLOWED
						case 'mods':
							MusicBeatState.switchState(new ModsManagerSelectorState());
						#end

						#if ACHIEVEMENTS_ALLOWED
						case 'achievements':
							MusicBeatState.switchState(backend.ScriptableState.tryCreate('AchievementsMenuState', new AchievementsMenuState()));
						#end

						case 'credits':
							MusicBeatState.switchState(backend.ScriptableState.tryCreate('CreditsState', new CreditsState()));
						case 'options':
							MusicBeatState.switchState(backend.ScriptableState.tryCreate('OptionsState', new OptionsState()));
							OptionsState.onPlayState = false;
							if (PlayState.SONG != null)
							{
								PlayState.SONG.arrowSkin = null;
								PlayState.SONG.splashSkin = null;
								PlayState.stageUI = 'normal';
							}
						default:
							trace('Menu Item ${option} doesn\'t do anything');
							selectedSomethin = false;
							item.visible = true;
					}
				});

				for (memb in menuItems)
				{
					if (memb == item)
						continue;

					FlxTween.tween(memb, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
				}
			}
			else if (controls.justPressed('debug_1') || touchPad.buttonE.justPressed)
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(backend.ScriptableState.tryCreate('MasterEditorMenu', new MasterEditorMenu()));
			}
		}

		super.update(elapsed);
	}

	function isMenuInputBlocked():Bool
	{
		if (menuItems == null)
			return false;
		return Reflect.field(menuItems, 'enabled') == false || Reflect.field(menuItems, 'busy') == true;
	}

	function changeItem(change:Int = 0)
	{
		if (change != 0)
			curColumn = CENTER;
		curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'));

		for (item in menuItems)
		{
			if (item.animation.exists('idle'))
				item.animation.play('idle');
			item.centerOffsets();
		}

		var selectedItem:FlxSprite;
		switch (curColumn)
		{
			case CENTER:
				selectedItem = menuItems.members[curSelected];
			case LEFT:
				selectedItem = leftItem;
			case RIGHT:
				selectedItem = rightItem;
		}
		if (selectedItem.animation.exists('selected'))
			selectedItem.animation.play('selected');
		selectedItem.centerOffsets();
		camFollow.y = selectedItem.getGraphicMidpoint().y;
	}
}

class PlusMainMenuItemGroup extends FlxTypedGroup<FlxSprite>
{
	public function new()
	{
		super();
	}

	public function addItem(id:String, item:FlxSprite):FlxSprite
	{
		return add(item);
	}
}


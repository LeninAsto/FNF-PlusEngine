package states;

import objects.AttachedSprite;
import flixel.effects.FlxFlicker;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class CreditsState extends MusicBeatState
{
	var curSelected:Int = -1;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<AttachedSprite> = [];
	private var creditsStuff:Array<Array<String>> = [];

	public var bg:FlxSprite;
	public var bgOverlay:FlxSprite;
	public var descText:FlxText;
	public var descBg:FlxSprite;
	public var intendedColor:FlxColor;
	public var colorTween:FlxTween;
	public var scrollFactorGroup:FlxTypedGroup<FlxSprite>;

	public var offsetThing:Float = -75;
	public var particleTimer:Float = 0;
	public var particles:Array<FlxSprite> = [];
	public var textAnimationTimer:FlxTimer = null;

	public var titleText:Alphabet;
	public var selectedBorder:FlxSprite;
	public var linkHint:FlxText;
	public var selectionGlow:FlxSprite;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = true;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = FlxColor.BLACK;
		bg.alpha = 0.9;
		add(bg);
		bg.screenCenter();

		bgOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bgOverlay.alpha = 0.3;
		add(bgOverlay);

		createParticles();

		selectionGlow = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		selectionGlow.alpha = 0.3;
		selectionGlow.blend = ADD;
		add(selectionGlow);

		selectedBorder = new FlxSprite();
		selectedBorder.makeGraphic(1, 1, FlxColor.WHITE);
		selectedBorder.alpha = 0;
		selectedBorder.antialiasing = ClientPrefs.data.antialiasing;
		add(selectedBorder);
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		titleText = new Alphabet(75, 45, Language.getPhrase("credits_title", "CREDITS"), true);
		titleText.setScale(0.6);
		titleText.scrollFactor.set(0, 0);
		titleText.alpha = 0.4;
		add(titleText);

		#if MODS_ALLOWED
		for (mod in Mods.parseList().enabled) pushModCreditsToList(mod);
		#end

		var defaultList:Array<Array<String>> = [ //Name - Icon name - Description - Link - BG Color
			['Plus Engine Team'],
			[
			'Lenin Asto',
			"len",              
			"Programmer of Plus Engine",                        
			"https://www.youtube.com/@Lenin_Anonimo_Of",
			"03FC88"
			],
			[
			'Andres',      
			'slushi',  
			'Creator and owner of several codes used based on the Slushi Engine',    
			'https://github.com/Slushi-Github',    
			'8FD9D1'
			],
			[
			'sirthegamercoder',	
			'sir',    
			'Indonesian translation and others PRs',       		
			'https://bsky.app/profile/stgmd.bsky.social',	     
			'7FDBFF'
			],
			[
			'TheoDev',             
			"theo",         
			"Owner, Lead coder of Funkin Modchart",                       
			"https://github.com/TheoDevelops",    
			"FFB347"
			],
			[''],
			['Mobile Porting Team'],
			['HomuHomu833',			'homura',             'Head Porter of Psych Engine and Author of linc_luajit-rewriten',                       'https://youtube.com/@HomuHomu833',		'FFE7C0'],
			['Karim Akra',			'karim',			'Second Porter of Psych Engine',						'https://youtube.com/@Karim0690',		'FFB4F0'],
			['Moxie',				'moxie',			'Helper of Psych Engine Mobile',							'https://twitter.com/moxie_specalist',  'F592C4'],
			[''],
			["Psych Engine Team"],
			["Shadow Mario",		"shadowmario",		"Main Programmer and Head of Psych Engine",					"https://ko-fi.com/shadowmario",	"444444"],
			["Riveren",				"riveren",			"Main Artist/Animator of Psych Engine",						"https://x.com/riverennn",			"14967B"],
			["bb-panzu",			"bb",				"Ex-Programmer of Psych Engine",							"https://x.com/bbsub3",				"3E813A"],
			[""],
			["Engine Contributors"],
			["crowplexus",			"crowplexus",	"Linux Support, HScript Iris, Input System v3, and Other PRs",	"https://twitter.com/IamMorwen",	"CFCFCF"],
			["Kamizeta",			"kamizeta",			"Creator of Pessy, Psych Engine's mascot.",				"https://www.instagram.com/cewweey/",	"D21C11"],
			["MaxNeton",			"maxneton",			"Loading Screen Easter Egg Artist/Animator.",	"https://bsky.app/profile/maxneton.bsky.social","3C2E4E"],
			["Keoiki",				"keoiki",			"Note Splash Animations and Latin Alphabet",				"https://x.com/Keoiki_",			"D2D2D2"],
			["SqirraRNG",			"sqirra",			"Crash Handler and Base code for\nChart Editor's Waveform",	"https://x.com/gedehari",			"E1843A"],
			["EliteMasterEric",		"mastereric",		"Runtime Shaders support and Other PRs",					"https://x.com/EliteMasterEric",	"FFBD40"],
			["MAJigsaw77",			"majigsaw",			".MP4 Video Loader Library (hxvlc)",						"https://x.com/MAJigsaw77",			"5F5F5F"],
			["iFlicky",				"flicky",			"Composer of Psync and Tea Time\nAnd some sound effects",	"https://x.com/flicky_i",			"9E29CF"],
			["KadeDev",				"kade",				"Fixed some issues on Chart Editor and Other PRs",			"https://x.com/kade0912",			"64A250"],
			["superpowers04",		"superpowers04",	"LUA JIT Fork",												"https://x.com/superpowers04",		"B957ED"],
			["CheemsAndFriends",	"cheems",			"Creator of FlxAnimate",									"https://x.com/CheemsnFriendos",	"E1E1E1"],
			[""],
			["Funkin' Crew"],
			["ninjamuffin99",		"ninjamuffin99",	"Programmer of Friday Night Funkin'",						"https://x.com/ninja_muffin99",		"CF2D2D"],
			["PhantomArcade",		"phantomarcade",	"Animator of Friday Night Funkin'",							"https://x.com/PhantomArcade3K",	"FADC45"],
			["evilsk8r",			"evilsk8r",			"Artist of Friday Night Funkin'",							"https://x.com/evilsk8r",			"5ABD4B"],
			["kawaisprite",			"kawaisprite",		"Composer of Friday Night Funkin'",							"https://x.com/kawaisprite",		"378FC7"],
			[""],
			["Psych Engine Discord"],
			["Join the Psych Ward!", "discord", "", "https://discord.gg/2ka77eMXDv", "5165F6"]
		];
		
		for(i in defaultList)
			creditsStuff.push(i);

		for (i => credit in creditsStuff)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(FlxG.width / 2, 300, credit[0], !isSelectable);
			optionText.isMenuItem = true;
			optionText.targetY = i;
			optionText.changeX = false;
			optionText.snapToPosition();
			optionText.alpha = 0;
			grpOptions.add(optionText);

			FlxTween.tween(optionText, {alpha: 1}, 0.5, {
				ease: FlxEase.quadOut,
				startDelay: 0.1 * i
			});

			if(isSelectable)
			{
				if(credit[5] != null)
					Mods.currentModDirectory = credit[5];

				var str:String = 'credits/missing_icon';
				if(credit[1] != null && credit[1].length > 0)
				{
					var fileName = 'credits/' + credit[1];
					if (Paths.fileExists('images/$fileName.png', IMAGE)) str = fileName;
					else if (Paths.fileExists('images/$fileName-pixel.png', IMAGE)) str = fileName + '-pixel';
				}

				var icon:AttachedSprite = new AttachedSprite(str);
				if(str.endsWith('-pixel')) icon.antialiasing = false;
				icon.xAdd = optionText.width + 10;
				icon.sprTracker = optionText;
				icon.alpha = 0;

				FlxTween.tween(icon, {alpha: 1}, 0.5, {
					ease: FlxEase.quadOut,
					startDelay: 0.1 * i + 0.2
				});
	
				iconArray.push(icon);
				add(icon);
				Mods.currentModDirectory = '';

				if(curSelected == -1) curSelected = i;
			}
			else optionText.alignment = CENTERED;
		}

		descBg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBg.alpha = 0.8;
		descBg.antialiasing = ClientPrefs.data.antialiasing;
		add(descBg);

		descText = new FlxText(50, FlxG.height + offsetThing - 25, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		descText.scrollFactor.set();
		descText.borderStyle = OUTLINE;
		descText.borderColor = FlxColor.BLACK;
		descText.borderSize = 2;
		add(descText);

		linkHint = new FlxText(20, FlxG.height - 40, FlxG.width - 40, Language.getPhrase("link_hint", "Press A/ENTER to open link | B/ESC to go back"), 20);
		linkHint.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		linkHint.borderSize = 2;
		linkHint.scrollFactor.set();
		linkHint.alpha = 0;
		add(linkHint);
		
		FlxTween.tween(linkHint, {alpha: 0.7}, 1.0, {ease: FlxEase.quadInOut, startDelay: 1.0});

		bg.color = CoolUtil.colorFromString(creditsStuff[curSelected][4]);
		intendedColor = bg.color;
		changeSelection();

		addTouchPad('UP_DOWN', 'A_B');

		super.create();
	}
	
	function createParticles()
	{
		for (i in 0...15)
		{
			var particle = new FlxSprite();
			particle.makeGraphic(Std.int(FlxG.random.float(2, 4)), Std.int(FlxG.random.float(2, 4)), FlxColor.WHITE);
			particle.alpha = FlxG.random.float(0.1, 0.3);
			particle.blend = ADD;
			particle.scrollFactor.set(0, 0);
			particle.x = FlxG.random.float(0, FlxG.width);
			particle.y = FlxG.random.float(0, FlxG.height);
			particles.push(particle);
			add(particle);
		}
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;
	var timeSinceLastScroll:Float = 0;
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
		}

		particleTimer += elapsed;
		if (particleTimer > 0.016)
		{
			particleTimer = 0;
			for (particle in particles)
			{
				particle.x += Math.cos(particle.y * 0.01) * 0.5;
				particle.y += Math.sin(particle.x * 0.01) * 0.5;
				
				if (particle.x > FlxG.width) particle.x = 0;
				if (particle.x < 0) particle.x = FlxG.width;
				if (particle.y > FlxG.height) particle.y = 0;
				if (particle.y < 0) particle.y = FlxG.height;
			}
		}

		if(!quitting)
		{
			timeSinceLastScroll += elapsed;
			
			if(creditsStuff.length > 1)
			{
				var shiftMult:Int = 1;
				if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

				var upP = controls.UI_UP_P || (touchPad != null && touchPad.buttonUp.justPressed);
				var downP = controls.UI_DOWN_P || (touchPad != null && touchPad.buttonDown.justPressed);

				if (upP)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
					timeSinceLastScroll = 0;
				}
				if (downP)
				{
					changeSelection(shiftMult);
					holdTime = 0;
					timeSinceLastScroll = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP || (touchPad != null && (touchPad.buttonDown.pressed || touchPad.buttonUp.pressed)))
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						var isUp = controls.UI_UP || (touchPad != null && touchPad.buttonUp.pressed);
						changeSelection((checkNewHold - checkLastHold) * (isUp ? -shiftMult : shiftMult));
						timeSinceLastScroll = 0;
					}
				}
			}

			if((controls.ACCEPT || (touchPad != null && touchPad.buttonA.justPressed)) && (creditsStuff[curSelected][3] == null || creditsStuff[curSelected][3].length > 4)) {
				var selectedText = grpOptions.members[curSelected];
				if (selectedText != null)
				{
					FlxFlicker.flicker(selectedText, 0.5, 0.06, true);
					FlxG.sound.play(Paths.sound('confirmMenu'));
				}

				new FlxTimer().start(0.3, function(tmr:FlxTimer) {
					CoolUtil.browserLoad(creditsStuff[curSelected][3]);
				});
			}
			if (controls.BACK || (touchPad != null && touchPad.buttonB.justPressed))
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				quitting = true;

				FlxTween.tween(titleText, {alpha: 0, y: titleText.y - 20}, 0.5, {ease: FlxEase.quadIn});
				for (item in grpOptions.members)
					FlxTween.tween(item, {alpha: 0}, 0.4, {ease: FlxEase.quadIn});
				for (icon in iconArray)
					FlxTween.tween(icon, {alpha: 0}, 0.4, {ease: FlxEase.quadIn});
				FlxTween.tween(descText, {alpha: 0}, 0.4, {ease: FlxEase.quadIn});
				FlxTween.tween(linkHint, {alpha: 0}, 0.4, {ease: FlxEase.quadIn});
				
				new FlxTimer().start(0.5, function(tmr:FlxTimer) {
					MusicBeatState.switchState(new MainMenuState());
				});
			}
		}

		for (item in grpOptions.members)
		{
			if(!item.bold)
			{
				var lerpVal:Float = Math.exp(-elapsed * 12);
				if(item.targetY == 0)
				{
					var lastX:Float = item.x;
					item.screenCenter(X);
					item.x = FlxMath.lerp(item.x - 70, lastX, lerpVal);

					selectionGlow.setPosition(item.x - 10, item.y + 45);
					selectionGlow.scale.set(item.width + 20, item.height + 10);
					selectionGlow.updateHitbox();
					selectionGlow.alpha = 0.2 + Math.sin(FlxG.game.ticks * 0.003) * 0.1;
				}
				else
				{
					item.x = FlxMath.lerp(200 + -40 * Math.abs(item.targetY), item.x, lerpVal);
				}

				item.y += Math.sin(item.targetY * 0.5 + FlxG.game.ticks * 0.001) * 0.5;
			}
		}

		if (selectedBorder.alpha > 0)
		{
			selectedBorder.scale.x = 1 + Math.sin(FlxG.game.ticks * 0.005) * 0.05;
			selectedBorder.scale.y = 1 + Math.sin(FlxG.game.ticks * 0.005) * 0.05;
		}
	}

	var moveTween:FlxTween = null;
	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do
		{
			curSelected = FlxMath.wrap(curSelected + change, 0, creditsStuff.length - 1);
		}
		while(unselectableCheck(curSelected));

		var newColor:FlxColor = CoolUtil.colorFromString(creditsStuff[curSelected][4]);
		if(newColor != intendedColor)
		{
			intendedColor = newColor;
			if(colorTween != null) colorTween.cancel();

			colorTween = FlxTween.color(bg, 0.8, bg.color, intendedColor, {
				onUpdate: function(twn:FlxTween) {
					var currentColor:FlxColor = bg.color;
					var pulseColor:FlxColor = currentColor.getLightened(0.1);
					bgOverlay.color = pulseColor;
				}
			});
		}

		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelected;
			if(!unselectableCheck(num)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;

					var selectedItem = grpOptions.members[curSelected];
					if (selectedItem != null)
					{
					selectedBorder.setPosition(selectedItem.x - 5, selectedItem.y + 10);
						selectedBorder.scale.set(selectedItem.width + 10, selectedItem.height + 10);
						selectedBorder.updateHitbox();
						selectedBorder.alpha = 0.8;

						FlxTween.cancelTweensOf(selectedBorder);
						selectedBorder.scale.set(selectedItem.width + 20, selectedItem.height + 20);
						FlxTween.tween(selectedBorder.scale, {x: selectedItem.width + 10, y: selectedItem.height + 10}, 
							0.2, {ease: FlxEase.backOut});
					}
				}
			}
		}

		descText.text = creditsStuff[curSelected][2];
		if(descText.text.trim().length > 0)
		{
			descText.visible = true;
			descBg.visible = true;
			descText.y = FlxG.height - descText.height + offsetThing - 60;

			descBg.setPosition(descText.x - 10, descText.y - 10);
			descBg.scale.set(descText.width + 20, descText.height + 20);
			descBg.updateHitbox();
	
			if(moveTween != null) moveTween.cancel();
			moveTween = FlxTween.tween(descText, {y : descText.y + 75}, 0.25, {ease: FlxEase.sineOut});
			FlxTween.tween(descBg, {y : descText.y + 75 - 10}, 0.25, {ease: FlxEase.sineOut});

			var fullText = descText.text;
			descText.text = "";
			if(textAnimationTimer != null) textAnimationTimer.cancel();
				textAnimationTimer = new FlxTimer().start(0.02, function(tmr:FlxTimer) {
				var currentLength = descText.text.length;
				if (currentLength < fullText.length) {
					descText.text = fullText.substr(0, currentLength + 1);
				}
			}, fullText.length);
		}
		else 
		{
			descText.visible = false;
			descBg.visible = false;
		}
	}

	#if MODS_ALLOWED
	function pushModCreditsToList(folder:String)
	{
		var creditsFile:String = Paths.mods(folder + '/data/credits.txt');
		
		#if TRANSLATIONS_ALLOWED
		var translatedCredits:String = Paths.mods(folder + '/data/credits-${ClientPrefs.data.language}.txt');
		#end

		if (#if TRANSLATIONS_ALLOWED (FileSystem.exists(translatedCredits) && (creditsFile = translatedCredits) == translatedCredits) || #end FileSystem.exists(creditsFile))
		{
			var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
			for(i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if(arr.length >= 5) arr.push(folder);
				creditsStuff.push(arr);
			}
			creditsStuff.push(['']);
		}
	}
	#end

	private function unselectableCheck(num:Int):Bool {
		return creditsStuff[num].length <= 1;
	}
}

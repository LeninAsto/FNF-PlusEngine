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
	public var descText:FlxText;
	public var descBg:FlxSprite;
	public var intendedColor:FlxColor;
	public var colorTween:FlxTween;

	public var offsetThing:Float = -75;

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

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

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
			grpOptions.add(optionText);

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

		bg.color = CoolUtil.colorFromString(creditsStuff[curSelected][4]);
		intendedColor = bg.color;
		changeSelection();

		addTouchPad('UP_DOWN', 'A_B');

		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
		}

		if(!quitting)
		{
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
				}
				if (downP)
				{
					changeSelection(shiftMult);
					holdTime = 0;
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
				if(colorTween != null)
					colorTween.cancel();

				FlxG.sound.play(Paths.sound('cancelMenu'));
				quitting = true;
				MusicBeatState.switchState(backend.ScriptableState.tryCreate('MainMenuState', new MainMenuState()));
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
				}
				else
				{
					item.x = FlxMath.lerp(200 + -40 * Math.abs(item.targetY), item.x, lerpVal);
				}
			}
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
				onComplete: function(twn:FlxTween) colorTween = null
			});
		}

		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelected;
			if(!unselectableCheck(num)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
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

package stages;

import backend.BaseStage;
import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import states.PlayState;
import stages.objects.MallCrowd;

/** Week 5, Cocoa and Eggnog. Ported from the compiled `states.stages.Mall`. **/
class Mall extends BaseStage {
	var upperBoppers:FlxSprite;
	var bottomBoppers:MallCrowd;
	var santa:FlxSprite;

	override function create():Void {
		var bg:FlxSprite = backdrop('christmas/bgWalls', -1000, -500, 0.2, 0.2);
		bg.setGraphicSize(Std.int(bg.width * 0.8));
		bg.updateHitbox();
		add(bg);

		if (!ClientPrefs.data.lowQuality) {
			upperBoppers = animProp('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
			upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
			upperBoppers.updateHitbox();
			add(upperBoppers);

			var bgEscalator:FlxSprite = backdrop('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
			bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
			bgEscalator.updateHitbox();
			add(bgEscalator);
		}

		var tree:FlxSprite = backdrop('christmas/christmasTree', 370, -250, 0.40, 0.40);
		add(tree);

		bottomBoppers = new MallCrowd(-300, 140);
		add(bottomBoppers);

		var fgSnow:FlxSprite = backdrop('christmas/fgSnow', -600, 700);
		add(fgSnow);

		Paths.sound('Lights_Shut_off');
		setDefaultGF('gf-christmas');

		if (isStoryMode && !seenCutscene) {
			setEndCallback(eggnogEndCutscene);
		}
	}

	override function createPost():Void {
		// Added after the characters exist so it renders in front of dad (who sits behind santa)
		// while staying behind bf.
		santa = animProp('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
		addBehindBF(santa);
	}

	override function countdownTick(count:Countdown, num:Int):Void {
		everyoneDance();
	}

	override function beatHit():Void {
		everyoneDance();
	}

	override function eventCalled(eventName:String, value1:String, value2:String, value3:String, value4:String, flValue1:Null<Float> = null, flValue2:Null<Float> = null, flValue3:Null<Float> = null, flValue4:Null<Float> = null, strumTime:Float):Void {
		if (eventName != 'Hey!') {
			return;
		}

		var who:String = value1.toLowerCase().trim();
		if (who == 'bf' || who == 'boyfriend' || who == '0') {
			return;
		}

		bottomBoppers.animation.play('hey', true);
		bottomBoppers.heyTimer = flValue2;
	}

	function everyoneDance():Void {
		if (!ClientPrefs.data.lowQuality) {
			upperBoppers.animation.play('Upper Crowd Bob', true);
		}

		bottomBoppers.dance(true);
		santa.animation.play('santa idle in fear', true);
	}

	function eggnogEndCutscene():Void {
		if (PlayState.storyPlaylist[1] == null) {
			endSong();
			return;
		}

		var nextSong:String = Paths.formatToSongPath(PlayState.storyPlaylist[1]);
		if (nextSong != 'winter-horrorland') {
			endSong();
			return;
		}

		FlxG.sound.play(Paths.sound('Lights_Shut_off'));

		var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom, -FlxG.height * FlxG.camera.zoom);
		blackShit.makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
		blackShit.scrollFactor.set(0, 0);
		add(blackShit);
		camHUD.visible = false;

		inCutscene = true;
		canPause = false;

		new FlxTimer().start(1.5, function(tmr:FlxTimer):Void {
			endSong();
		});
	}

	/**
		A static backdrop at a scroll factor, inert because it never animates. This is what the
		engine's old `BGSprite` constructor did; the class is gone, so each stage does it itself.
	**/
	function backdrop(image:String, x:Float, y:Float, scrollX:Float = 1, scrollY:Float = 1):FlxSprite {
		var spr:FlxSprite = new FlxSprite(x, y);
		if (image != null) {
			spr.loadGraphic(Paths.image(image));
		}
		spr.scrollFactor.set(scrollX, scrollY);
		spr.active = false;
		spr.antialiasing = ClientPrefs.data.antialiasing;
		return spr;
	}

	/** An animated backdrop: one animation per prefix, the first playing as the idle. **/
	function animProp(image:String, x:Float, y:Float, scrollX:Float, scrollY:Float, anims:Array<String>, loop:Bool = false):FlxSprite {
		var spr:FlxSprite = new FlxSprite(x, y);
		spr.frames = Paths.getSparrowAtlas(image);
		for (anim in anims) {
			spr.animation.addByPrefix(anim, anim, 24, loop);
		}
		spr.animation.play(anims[0]);
		spr.scrollFactor.set(scrollX, scrollY);
		spr.antialiasing = ClientPrefs.data.antialiasing;
		return spr;
	}
}

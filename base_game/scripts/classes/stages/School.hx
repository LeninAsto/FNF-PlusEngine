package stages;

import backend.BaseStage;
import backend.ClientPrefs;
import backend.CoolUtil;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import states.PlayState;
import stages.objects.SenpaiDialogueBox;
import stages.objects.BackgroundGirls;
import substates.GameOverSubstate;

/**
	Week 6, Senpai and Roses. Ported from the compiled `states.stages.School`.

	Callbacks handed to the dialogue box are wrapped in closures rather than passed as bare method
	references: a script's method is not a compiled `Void->Void`, so the closure keeps the boundary
	honest.
**/
class School extends BaseStage {
	var bgGirls:BackgroundGirls;
	var doof:SenpaiDialogueBox = null;

	override function create():Void {
		var song:Dynamic = PlayState.SONG;
		if (song.gameOverSound == null || song.gameOverSound.trim().length < 1) {
			GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
		}
		if (song.gameOverLoop == null || song.gameOverLoop.trim().length < 1) {
			GameOverSubstate.loopSoundName = 'gameOver-pixel';
		}
		if (song.gameOverEnd == null || song.gameOverEnd.trim().length < 1) {
			GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
		}
		if (song.gameOverChar == null || song.gameOverChar.trim().length < 1) {
			GameOverSubstate.characterName = 'bf-pixel-dead';
		}

		var bgSky:FlxSprite = backdrop('weeb/weebSky', 0, 0, 0.1, 0.1);
		add(bgSky);
		bgSky.antialiasing = false;

		var repositionShit:Int = -200;

		var bgSchool:FlxSprite = backdrop('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
		add(bgSchool);
		bgSchool.antialiasing = false;

		var bgStreet:FlxSprite = backdrop('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
		add(bgStreet);
		bgStreet.antialiasing = false;

		var widShit:Int = Std.int(bgSky.width * PlayState.daPixelZoom);
		if (!ClientPrefs.data.lowQuality) {
			var fgTrees:FlxSprite = backdrop('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
			fgTrees.setGraphicSize(Std.int(widShit * 0.8));
			fgTrees.updateHitbox();
			add(fgTrees);
			fgTrees.antialiasing = false;
		}

		var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
		bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
		bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
		bgTrees.animation.play('treeLoop');
		bgTrees.scrollFactor.set(0.85, 0.85);
		add(bgTrees);
		bgTrees.antialiasing = false;

		if (!ClientPrefs.data.lowQuality) {
			var treeLeaves:FlxSprite = animProp('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
			treeLeaves.setGraphicSize(widShit);
			treeLeaves.updateHitbox();
			add(treeLeaves);
			treeLeaves.antialiasing = false;
		}

		bgSky.setGraphicSize(widShit);
		bgSchool.setGraphicSize(widShit);
		bgStreet.setGraphicSize(widShit);
		bgTrees.setGraphicSize(Std.int(widShit * 1.4));

		bgSky.updateHitbox();
		bgSchool.updateHitbox();
		bgStreet.updateHitbox();
		bgTrees.updateHitbox();

		if (!ClientPrefs.data.lowQuality) {
			bgGirls = new BackgroundGirls(-100, 190);
			bgGirls.scrollFactor.set(0.9, 0.9);
			add(bgGirls);
		}
		setDefaultGF('gf-pixel');

		if (songName == 'senpai') {
			FlxG.sound.playMusic(Paths.music('Lunchbox'), 0);
			FlxG.sound.music.fadeIn(1, 0, 0.8);
		} else if (songName == 'roses') {
			FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));
		}

		if (isStoryMode && !seenCutscene) {
			if (songName == 'roses') {
				FlxG.sound.play(Paths.sound('ANGRY'));
			}
			initDoof();
			setStartCallback(schoolIntro);
		}
	}

	override function beatHit():Void {
		if (bgGirls != null) {
			bgGirls.dance();
		}
	}

	// For events
	override function eventCalled(eventName:String, value1:String, value2:String, value3:String, value4:String, flValue1:Null<Float> = null, flValue2:Null<Float> = null, flValue3:Null<Float> = null, flValue4:Null<Float> = null, strumTime:Float):Void {
		if (eventName == 'BG Freaks Expression' && bgGirls != null) {
			bgGirls.swapDanceType();
		}
	}

	function initDoof():Void {
		// Checks for vanilla/Senpai dialogue
		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue_' + ClientPrefs.data.language);
		if (!FileSystem.exists(file)) {
			file = Paths.txt(songName + '/' + songName + 'Dialogue');
		}

		if (!FileSystem.exists(file)) {
			startCountdown();
			return;
		}

		doof = new SenpaiDialogueBox(false, CoolUtil.coolTextFile(file));
		doof.cameras = [camHUD];
		doof.scrollFactor.set(0, 0);
		doof.finishThing = function():Void {
			startCountdown();
		};
		doof.nextDialogueThing = function():Void {
			PlayState.instance.startNextDialogue();
		};
		doof.skipDialogueThing = function():Void {
			PlayState.instance.skipDialogue();
		};
	}

	function schoolIntro():Void {
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100);
		black.makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set(0, 0);
		if (songName == 'senpai') {
			add(black);
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer):Void {
			black.alpha -= 0.15;

			if (black.alpha <= 0) {
				if (doof != null) {
					add(doof);
				} else {
					startCountdown();
				}

				remove(black);
				black.destroy();
			} else {
				tmr.reset(0.3);
			}
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

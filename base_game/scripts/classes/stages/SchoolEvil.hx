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
import flixel.addons.effects.FlxTrail;
import substates.GameOverSubstate;

/** Week 6, Thorns. Ported from the compiled `states.stages.SchoolEvil`. **/
class SchoolEvil extends BaseStage {
	// Ghouls event
	var bgGhouls:FlxSprite;
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

		var posX:Int = 400;
		var posY:Int = 200;

		var bg:FlxSprite;
		if (!ClientPrefs.data.lowQuality) {
			bg = animProp('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
		} else {
			bg = backdrop('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
		}

		bg.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
		bg.antialiasing = false;
		add(bg);
		setDefaultGF('gf-pixel');

		FlxG.sound.playMusic(Paths.music('LunchboxScary'), 0);
		FlxG.sound.music.fadeIn(1, 0, 0.8);
		if (isStoryMode && !seenCutscene) {
			initDoof();
			setStartCallback(schoolIntro);
		}
	}

	override function createPost():Void {
		var trail:FlxTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
		addBehindDad(trail);
	}

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float):Void {
		if (eventName == 'Trigger BG Ghouls' && !ClientPrefs.data.lowQuality) {
			bgGhouls.animation.play('BG freaks glitch instance', true);
			bgGhouls.visible = true;
		}
	}

	// used for preloading assets used on events
	override function eventPushed(event:Dynamic):Void {
		if (event.event != 'Trigger BG Ghouls' || ClientPrefs.data.lowQuality) {
			return;
		}

		bgGhouls = animProp('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
		bgGhouls.setGraphicSize(Std.int(bgGhouls.width * PlayState.daPixelZoom));
		bgGhouls.updateHitbox();
		bgGhouls.visible = false;
		bgGhouls.antialiasing = false;
		bgGhouls.animation.finishCallback = function(name:String):Void {
			if (name == 'BG freaks glitch instance') {
				bgGhouls.visible = false;
			}
		};
		addBehindGF(bgGhouls);
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
		var red:FlxSprite = new FlxSprite(-100, -100);
		red.makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set(0, 0);
		add(red);

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set(0, 0);
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;
		camHUD.visible = false;

		new FlxTimer().start(2.1, function(tmr:FlxTimer):Void {
			if (doof == null) {
				return;
			}

			add(senpaiEvil);
			senpaiEvil.alpha = 0;
			new FlxTimer().start(0.3, function(swagTimer:FlxTimer):Void {
				senpaiEvil.alpha += 0.15;
				if (senpaiEvil.alpha < 1) {
					swagTimer.reset(0.3);
					return;
				}

				senpaiEvil.animation.play('idle');
				FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function():Void {
					remove(senpaiEvil);
					senpaiEvil.destroy();
					remove(red);
					red.destroy();
					FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function():Void {
						add(doof);
						camHUD.visible = true;
					}, true);
				});
				new FlxTimer().start(3.2, function(deadTime:FlxTimer):Void {
					FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
				});
			});
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

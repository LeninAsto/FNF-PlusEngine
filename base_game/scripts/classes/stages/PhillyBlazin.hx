package stages;

import backend.BaseStage;
import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.display.BlendMode;
import states.PlayState;
import flixel.addons.display.FlxTiledSprite;
import openfl.filters.ShaderFilter;
import shaders.RainShader;
import stages.objects.ABotSpeaker;
import stages.objects.DarnellBlazinHandler;
import stages.objects.PicoBlazinHandler;
import substates.GameOverSubstate;

/** Weekend 1, Blazin'. Ported from the compiled `states.stages.PhillyBlazin`. **/
class PhillyBlazin extends BaseStage {
	var rainShader:RainShader;
	var rainTimeScale:Float = 1;

	var scrollingSky:FlxTiledSprite;
	var skyAdditive:FlxSprite;
	var lightning:FlxSprite;
	var foregroundMultiply:FlxSprite;
	var additionalLighten:FlxSprite;

	var lightningTimer:Float = 3.0;

	var abot:ABotSpeaker;

	// Note functions
	var picoFight:PicoBlazinHandler = new PicoBlazinHandler();
	var darnellFight:DarnellBlazinHandler = new DarnellBlazinHandler();

	override function create():Void {
		FlxTransitionableState.skipNextTransOut = true; // skip the original transition fade

		if (!ClientPrefs.data.lowQuality) {
			var skyImage:Dynamic = Paths.image('phillyBlazin/skyBlur');
			scrollingSky = new FlxTiledSprite(skyImage, Std.int(skyImage.width * 1.1) + 475, Std.int(skyImage.height / 1.1), true, false);
			scrollingSky.antialiasing = ClientPrefs.data.antialiasing;
			scrollingSky.setPosition(-500, -120);
			scrollingSky.scrollFactor.set(0, 0);
			add(scrollingSky);

			skyAdditive = backdrop('phillyBlazin/skyBlur', -600, -175, 0.0, 0.0);
			setupScale(skyAdditive);
			skyAdditive.visible = false;
			add(skyAdditive);

			lightning = animProp('phillyBlazin/lightning', -50, -300, 0.0, 0.0, ['lightning0'], false);
			setupScale(lightning);
			lightning.visible = false;
			add(lightning);
		}

		var phillyForegroundCity:FlxSprite = backdrop('phillyBlazin/streetBlur', -600, -175, 0.0, 0.0);
		setupScale(phillyForegroundCity);
		add(phillyForegroundCity);

		if (!ClientPrefs.data.lowQuality) {
			foregroundMultiply = backdrop('phillyBlazin/streetBlur', -600, -175, 0.0, 0.0);
			setupScale(foregroundMultiply);
			foregroundMultiply.blend = BlendMode.MULTIPLY;
			foregroundMultiply.visible = false;
			add(foregroundMultiply);

			additionalLighten = new FlxSprite(-600, -175);
			additionalLighten.makeGraphic(1, 1, FlxColor.WHITE);
			additionalLighten.scrollFactor.set(0, 0);
			additionalLighten.scale.set(2500, 2500);
			additionalLighten.updateHitbox();
			additionalLighten.blend = BlendMode.ADD;
			additionalLighten.visible = false;
			add(additionalLighten);
		}

		abot = new ABotSpeaker(gfGroup.x, gfGroup.y + 550);
		add(abot);

		if (ClientPrefs.data.shaders) {
			setupRainShader();
		}

		var song:Dynamic = PlayState.SONG;
		if (song.gameOverSound == null || song.gameOverSound.trim().length < 1) {
			GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pico-gutpunch';
		}
		if (song.gameOverLoop == null || song.gameOverLoop.trim().length < 1) {
			GameOverSubstate.loopSoundName = 'gameOver-pico';
		}
		if (song.gameOverEnd == null || song.gameOverEnd.trim().length < 1) {
			GameOverSubstate.endSoundName = 'gameOverEnd-pico';
		}
		if (song.gameOverChar == null || song.gameOverChar.trim().length < 1) {
			GameOverSubstate.characterName = 'pico-blazin';
		}
		GameOverSubstate.deathDelay = 0.15;

		setDefaultGF('nene');
		precache();

		if (isStoryMode && songName == 'blazin') {
			setEndCallback(function():Void {
				PlayState.instance.endingSong = true;
				inCutscene = true;
				canPause = false;
				FlxTransitionableState.skipNextTransIn = true;
				FlxG.camera.visible = false;
				camHUD.visible = false;
				PlayState.instance.startVideo('blazinCutscene');
			});
		}
	}

	function setupScale(spr:FlxSprite):Void {
		spr.scale.set(1.75, 1.75);
		spr.updateHitbox();
	}

	override function createPost():Void {
		FlxG.camera.focusOn(camFollow.getPosition());
		FlxG.camera.fade(FlxColor.BLACK, 1.5, true, null, true);

		for (character in boyfriendGroup.members) {
			if (character != null) {
				character.color = 0xFFDEDEDE;
			}
		}
		for (character in dadGroup.members) {
			if (character != null) {
				character.color = 0xFFDEDEDE;
			}
		}
		for (character in gfGroup.members) {
			if (character != null) {
				character.color = 0xFF888888;
			}
		}
		abot.color = 0xFF888888;

		remove(dadGroup, true);
		addBehindBF(dadGroup);
	}

	// override animations for note types
	override function notesGenerated(notes:Array<Dynamic>):Void {
		for (note in notes) {
			note.noAnimation = true;
			note.noMissAnimation = true;
		}
	}

	override function startSong():Void {
		abot.snd = FlxG.sound.music;
	}

	function setupRainShader():Void {
		rainShader = new RainShader();
		rainShader.scale = FlxG.height / 200;
		rainShader.intensity = 0.5;
		FlxG.camera.filters = [new ShaderFilter(rainShader)];
	}

	function precache():Void {
		for (i in 1...4) {
			Paths.sound('lightning/Lightning' + i);
		}
	}

	override function update(elapsed:Float):Void {
		if (scrollingSky != null) {
			scrollingSky.scrollX -= elapsed * 35;
		}

		if (rainShader != null) {
			rainShader.updateViewInfo(FlxG.width, FlxG.height, FlxG.camera);
			rainShader.update(elapsed * rainTimeScale);
			rainTimeScale = FlxMath.lerp(0.02, Math.min(1, rainTimeScale), Math.exp(-elapsed / (1 / 3)));
		}

		lightningTimer -= elapsed;
		if (lightningTimer <= 0) {
			applyLightning();
			lightningTimer = FlxG.random.float(7, 15);
		}
	}

	function applyLightning():Void {
		if (ClientPrefs.data.lowQuality || PlayState.instance.endingSong) {
			return;
		}

		var LIGHTNING_FULL_DURATION:Float = 1.5;
		var LIGHTNING_FADE_DURATION:Float = 0.3;

		skyAdditive.visible = true;
		skyAdditive.alpha = 0.7;
		FlxTween.tween(skyAdditive, {alpha: 0.0}, LIGHTNING_FULL_DURATION, {
			onComplete: function(twn:FlxTween):Void {
				skyAdditive.visible = false;
				lightning.visible = false;
				foregroundMultiply.visible = false;
				additionalLighten.visible = false;
			}
		});

		foregroundMultiply.visible = true;
		foregroundMultiply.alpha = 0.64;
		FlxTween.tween(foregroundMultiply, {alpha: 0.0}, LIGHTNING_FULL_DURATION);

		additionalLighten.visible = true;
		additionalLighten.alpha = 0.3;
		FlxTween.tween(additionalLighten, {alpha: 0.0}, LIGHTNING_FADE_DURATION);

		lightning.visible = true;
		lightning.animation.play('lightning0', true);

		if (FlxG.random.bool(65)) {
			lightning.x = FlxG.random.int(-250, 280);
		} else {
			lightning.x = FlxG.random.int(780, 900);
		}

		// Darken characters
		FlxTween.color(boyfriend, LIGHTNING_FADE_DURATION, 0xFF606060, 0xFFDEDEDE);
		FlxTween.color(dad, LIGHTNING_FADE_DURATION, 0xFF606060, 0xFFDEDEDE);
		FlxTween.color(gf, LIGHTNING_FADE_DURATION, 0xFF606060, 0xFF888888);
		FlxTween.color(abot, LIGHTNING_FADE_DURATION, 0xFF606060, 0xFF888888);

		// Sound
		FlxG.sound.play(Paths.soundRandom('lightning/Lightning', 1, 3));
	}

	override function goodNoteHit(note:Dynamic):Void {
		rainTimeScale += 0.7;
		picoFight.noteHit(note);
		darnellFight.noteHit(note);
	}

	override function noteMiss(note:Dynamic):Void {
		picoFight.noteMiss(note);
		darnellFight.noteMiss(note);
	}

	override function noteMissPress(direction:Int):Void {
		picoFight.noteMissPress(direction);
		darnellFight.noteMissPress(direction);
	}

	// Darnell Note functions
	override function opponentNoteHit(note:Dynamic):Void {
		picoFight.noteMiss(note);
		darnellFight.noteMiss(note);
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

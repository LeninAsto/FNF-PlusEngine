package stages.objects;

import backend.Controls;
import backend.Language;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import states.PlayState;
import flixel.addons.text.FlxTypeText;
// Imported as MODULES so their sibling types (`FlxTextBorderStyle`, `FlxTextAlign`) come in as bare
// names -- a global import registers only the one type it names.
import flixel.text.FlxText;
import flixel.util.FlxAxes;
import backend.Song;

/**
	Week 6's pixel dialogue box: Senpai, his angry variant, and the Spirit. Ported from the compiled
	`cutscenes.DialogueBox`, which existed only to render these three and left the engine with it.

	Mods wanting dialogue use `DialogueBoxPsych`, which is data-driven off `dialogue.json`. This one
	is hardcoded to the songs it was written for, which is exactly why it belongs here.
**/
class SenpaiDialogueBox extends FlxSpriteGroup {
	public var finishThing:Void->Void;
	public var nextDialogueThing:Void->Void = null;
	public var skipDialogueThing:Void->Void = null;

	var box:FlxSprite;
	var curCharacter:String = '';
	var dialogueList:Array<String> = [];
	var swagDialogue:FlxTypeText;

	var portraitLeft:FlxSprite;
	var portraitRight:FlxSprite;

	var handSelect:FlxSprite;
	var bgFade:FlxSprite;
	var skipText:FlxText;

	var songName:String = '';

	var dialogueOpened:Bool = false;
	var dialogueStarted:Bool = false;
	var dialogueEnded:Bool = false;
	var isEnding:Bool = false;

	public function new(talkingRight:Bool = true, dialogueList:Array<String> = null) {
		super();

		songName = Paths.formatToSongPath(Song.loadedSongName);

		bgFade = new FlxSprite(-200, -200);
		bgFade.makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), 0xFFB3DFd8);
		bgFade.scrollFactor.set(0, 0);
		bgFade.alpha = 0;
		add(bgFade);

		new FlxTimer().start(0.83, function(tmr:FlxTimer):Void {
			bgFade.alpha += (1 / 5) * 0.7;
			if (bgFade.alpha > 0.7) {
				bgFade.alpha = 0.7;
			}
		}, 5);

		box = new FlxSprite(-20, 45);

		var hasDialog:Bool = true;
		switch (songName) {
			case 'senpai':
				box.frames = Paths.getSparrowAtlas('weeb/dialogue/dialogueBox-pixel');
				box.animation.addByPrefix('normalOpen', 'Text Box Appear', 24, false);
				box.animation.addByIndices('normal', 'Text Box Appear instance 1', [4], '', 24);
			case 'roses':
				box.frames = Paths.getSparrowAtlas('weeb/dialogue/dialogueBox-senpaiMad');
				box.animation.addByPrefix('normalOpen', 'SENPAI ANGRY IMPACT SPEECH', 24, false);
				box.animation.addByIndices('normal', 'SENPAI ANGRY IMPACT SPEECH instance 1', [4], '', 24);
			case 'thorns':
				box.frames = Paths.getSparrowAtlas('weeb/dialogue/dialogueBox-evil');
				box.animation.addByPrefix('normalOpen', 'Spirit Textbox spawn', 24, false);
				box.animation.addByIndices('normal', 'Spirit Textbox spawn instance 1', [11], '', 24);

				var face:FlxSprite = new FlxSprite(320, 170);
				face.loadGraphic(Paths.image('weeb/spiritFaceForward'));
				face.setGraphicSize(Std.int(face.width * 6));
				face.antialiasing = false;
				add(face);
			default:
				hasDialog = false;
		}

		this.dialogueList = dialogueList;

		if (!hasDialog) {
			// Don't leave a content-less dialogue substate sitting on top of the play state forever:
			// disabling updates and draws lets the parent state advance past it immediately.
			active = false;
			visible = false;
			return;
		}

		portraitLeft = new FlxSprite(-20, 40);
		portraitLeft.frames = Paths.getSparrowAtlas('weeb/senpaiPortrait');
		portraitLeft.animation.addByPrefix('enter', 'Senpai Portrait Enter', 24, false);
		portraitLeft.setGraphicSize(Std.int(portraitLeft.width * PlayState.daPixelZoom * 0.9));
		portraitLeft.updateHitbox();
		portraitLeft.scrollFactor.set(0, 0);
		portraitLeft.antialiasing = false;
		add(portraitLeft);
		portraitLeft.visible = false;

		portraitRight = new FlxSprite(0, 40);
		portraitRight.frames = Paths.getSparrowAtlas('weeb/bfPortrait');
		portraitRight.animation.addByPrefix('enter', 'Boyfriend portrait enter', 24, false);
		portraitRight.setGraphicSize(Std.int(portraitRight.width * PlayState.daPixelZoom * 0.9));
		portraitRight.updateHitbox();
		portraitRight.scrollFactor.set(0, 0);
		portraitRight.antialiasing = false;
		add(portraitRight);
		portraitRight.visible = false;

		box.animation.play('normalOpen');
		box.setGraphicSize(Std.int(box.width * PlayState.daPixelZoom * 0.9));
		box.updateHitbox();
		box.antialiasing = false;
		add(box);

		box.screenCenter(FlxAxes.X);
		portraitLeft.screenCenter(FlxAxes.X);

		handSelect = new FlxSprite(1042, 590);
		handSelect.loadGraphic(Paths.image('weeb/dialogue/hand_textbox'));
		handSelect.setGraphicSize(Std.int(handSelect.width * PlayState.daPixelZoom * 0.9));
		handSelect.updateHitbox();
		handSelect.antialiasing = false;
		handSelect.visible = false;
		add(handSelect);

		swagDialogue = new FlxTypeText(240, 500, Std.int(FlxG.width * 0.6), '', 32);
		swagDialogue.font = Paths.font('pixel-latin.ttf');
		swagDialogue.color = 0xFF3F2021;
		swagDialogue.sounds = [FlxG.sound.load(Paths.sound('pixelText'), 0.6)];
		swagDialogue.borderStyle = FlxTextBorderStyle.SHADOW;
		swagDialogue.borderColor = 0xFFD89494;
		swagDialogue.shadowOffset.set(2, 2);
		add(swagDialogue);

		skipText = new FlxText(FlxG.width - 320, FlxG.height - 30, 300, Language.getPhrase('dialogue_skip', 'Press BACK to Skip'), 16);
		skipText.setFormat(null, 16, FlxColor.WHITE, FlxTextAlign.RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
		skipText.borderSize = 2;
		add(skipText);
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (songName == 'roses') {
			portraitLeft.visible = false;
		} else if (songName == 'thorns') {
			portraitLeft.visible = false;
			swagDialogue.color = FlxColor.WHITE;
			swagDialogue.borderStyle = FlxTextBorderStyle.NONE;
		}

		if (box.animation.curAnim != null && box.animation.curAnim.name == 'normalOpen' && box.animation.curAnim.finished) {
			box.animation.play('normal');
			dialogueOpened = true;
		}

		if (dialogueOpened && !dialogueStarted) {
			startDialogue();
			dialogueStarted = true;
		}

		if (Controls.instance.BACK) {
			if (dialogueStarted && !isEnding) {
				dialogueCompleted();
				FlxG.sound.play(Paths.sound('clickText'), 0.8);
			}
		} else if (Controls.instance.ACCEPT) {
			if (dialogueEnded) {
				if (dialogueList[1] == null && dialogueList[0] != null) {
					if (!isEnding) {
						dialogueCompleted();
					}
				} else {
					dialogueList.remove(dialogueList[0]);
					startDialogue();
					FlxG.sound.play(Paths.sound('clickText'), 0.8);
				}
			} else if (dialogueStarted) {
				FlxG.sound.play(Paths.sound('clickText'), 0.8);
				swagDialogue.skip();

				if (skipDialogueThing != null) {
					skipDialogueThing();
				}
			}
		}
	}

	function dialogueCompleted():Void {
		isEnding = true;
		FlxG.sound.play(Paths.sound('clickText'), 0.8);

		if (songName == 'senpai' || songName == 'thorns') {
			FlxG.sound.music.fadeOut(1.5, 0, function(twn:FlxTween):Void {
				FlxG.sound.music.stop();
			});
		}

		new FlxTimer().start(0.2, function(tmr:FlxTimer):Void {
			box.alpha -= 1 / 5;
			bgFade.alpha -= 1 / 5 * 0.7;
			portraitLeft.visible = false;
			portraitRight.visible = false;
			swagDialogue.alpha -= 1 / 5;
			handSelect.alpha -= 1 / 5;
		}, 5);

		swagDialogue.skip();
		skipText.visible = false;

		new FlxTimer().start(1.5, function(tmr:FlxTimer):Void {
			if (finishThing != null) {
				finishThing();
			}
			kill();
		});
	}

	function startDialogue():Void {
		cleanDialog();

		swagDialogue.resetText(dialogueList[0]);
		swagDialogue.start(0.04, true);
		swagDialogue.completeCallback = function():Void {
			handSelect.visible = true;
			dialogueEnded = true;
		};

		handSelect.visible = false;
		dialogueEnded = false;

		if (curCharacter == 'dad') {
			portraitRight.visible = false;
			if (!portraitLeft.visible) {
				if (songName == 'senpai') {
					portraitLeft.visible = true;
				}
				portraitLeft.animation.play('enter');
			}
		} else if (curCharacter == 'bf') {
			portraitLeft.visible = false;
			if (!portraitRight.visible) {
				portraitRight.visible = true;
				portraitRight.animation.play('enter');
			}
		}

		if (nextDialogueThing != null) {
			nextDialogueThing();
		}
	}

	function cleanDialog():Void {
		var splitName:Array<String> = dialogueList[0].split(':');
		// A line without a "char:text" prefix would crash on splitName[1].length; keep the previous
		// character instead.
		if (splitName.length < 2 || splitName[1] == null) {
			return;
		}
		curCharacter = splitName[1];
		dialogueList[0] = dialogueList[0].substr(splitName[1].length + 2).trim();
	}
}

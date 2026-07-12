package backend;

import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import states.MainMenuState;

class CustomFadeTransition extends MusicBeatSubstate {
	public static var finishCallback:Void->Void;
	var isTransIn:Bool = false;

	public static var isTransitioning:Bool = false;
	public static var currentTransition:CustomFadeTransition = null;

	var topDoor:FlxSprite;
	var bottomDoor:FlxSprite;
	var waterMark:FlxText;
	var eventText:FlxText;
	var iconSprite:FlxSprite;

	var transBlack:FlxSprite;
	var transGradient:FlxSprite;

	var duration:Float;

	var topDoorTween:FlxTween;
	var bottomDoorTween:FlxTween;
	var textTween:FlxTween;
	var iconTween:FlxTween;

	var isDestroyed:Bool = false;
	var isClosing:Bool = false;
	var activeTweens:Array<FlxTween> = [];
	var transitionId:String;

	static function generateId():String {
		return 'transition_' + Date.now().getTime() + '_' + Math.floor(Math.random() * 1000);
	}

	public static function initCustomTransitionScript():Void {
		// Legacy hook preserved for compatibility.
	}

	public static function cancelCurrentTransition():Void {
		if (currentTransition != null && !currentTransition.isDestroyed) {
			currentTransition.forceClose();
		}

		isTransitioning = false;
		currentTransition = null;
		finishCallback = null;
	}

	function addTween(tween:FlxTween):FlxTween {
		if (tween != null) {
			activeTweens.push(tween);
		}
		return tween;
	}

	public function new(duration:Float = 0.5, isTransIn:Bool) {
		this.duration = duration;
		this.isTransIn = isTransIn;
		this.activeTweens = [];
		this.transitionId = generateId();

		if (currentTransition != null && currentTransition != this) {
			cancelCurrentTransition();
		}

		currentTransition = this;
		isTransitioning = true;

		super();
	}

	override function create() {
		super.create();

		if (currentTransition != this) {
			forceClose();
			return;
		}

		try {
			var cam:FlxCamera = new FlxCamera();
			cam.bgColor = 0x00;

			#if mobile
			cam.followLerp = 0;
			cam.pixelPerfectRender = false;
			#end

			FlxG.cameras.add(cam, false);
			cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

			if (ClientPrefs.data.vanillaTransition) {
				createVanillaTransition();
			} else {
				createCustomTransition();
			}
		} catch (e:Dynamic) {
			forceUnlock();
		}
	}

	function createVanillaTransition():Void {
		var width:Int = Std.int(FlxG.width / Math.max(camera.zoom, 0.001));
		var height:Int = Std.int(FlxG.height / Math.max(camera.zoom, 0.001));

		transGradient = FlxGradient.createGradientFlxSprite(1, height, (isTransIn ? [0x0, FlxColor.BLACK] : [FlxColor.BLACK, 0x0]));
		transGradient.scale.x = width;
		transGradient.updateHitbox();
		transGradient.scrollFactor.set();
		transGradient.screenCenter(X);
		add(transGradient);

		transBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		transBlack.scale.set(width, height + 400);
		transBlack.updateHitbox();
		transBlack.scrollFactor.set();
		transBlack.screenCenter(X);
		add(transBlack);

		if (isTransIn)
			transGradient.y = transBlack.y - transBlack.height;
		else
			transGradient.y = -transGradient.height;
	}

	function createCustomTransition():Void {
		var width:Int = FlxG.width;
		var height:Int = FlxG.height;

		topDoor = new FlxSprite();
		topDoor.loadGraphic(Paths.image('ui/transition/transUp'));
		topDoor.scrollFactor.set();
		topDoor.setGraphicSize(width, height);
		topDoor.updateHitbox();
		topDoor.antialiasing = ClientPrefs.data.antialiasing;

		bottomDoor = new FlxSprite();
		bottomDoor.loadGraphic(Paths.image('ui/transition/transDown'));
		bottomDoor.scrollFactor.set();
		bottomDoor.setGraphicSize(width, height);
		bottomDoor.updateHitbox();
		bottomDoor.antialiasing = ClientPrefs.data.antialiasing;

		iconSprite = new FlxSprite();
		iconSprite.loadGraphic(Paths.image('loading_screen/icon'));
		iconSprite.scrollFactor.set();
		iconSprite.scale.set(0.5, 0.5);
		iconSprite.screenCenter();

		waterMark = new FlxText(0, height - 140, 300, 'Plus Engine\nv${MainMenuState.plusEngineVersion}', 32);
		waterMark.x = (width - waterMark.width) / 2;
		waterMark.setFormat(Paths.font('NotoSans-Medium.ttf'), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		waterMark.scrollFactor.set();
		waterMark.borderSize = 2;

		eventText = new FlxText(50, height - 60, 300, '', 28);
		eventText.x = (width - eventText.width) / 2;
		eventText.setFormat(Paths.font('NotoSans-Medium.ttf'), 28, FlxColor.YELLOW, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		eventText.scrollFactor.set();
		eventText.borderSize = 2;

		if (isTransIn)
			createTransitionIn(width, height);
		else
			createTransitionOut(width, height);
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (ClientPrefs.data.vanillaTransition && transGradient != null) {
			final height:Float = FlxG.height * Math.max(camera.zoom, 0.001);
			final targetPos:Float = transGradient.height + 50 * Math.max(camera.zoom, 0.001);
			if (duration > 0)
				transGradient.y += (height + targetPos) * elapsed / duration;
			else
				transGradient.y = (targetPos) * elapsed;

			if (isTransIn)
				transBlack.y = transGradient.y + transGradient.height;
			else
				transBlack.y = transGradient.y - transBlack.height;

			if (transGradient.y >= targetPos)
				safeClose();
		}
	}

	function createTransitionIn(width:Int, height:Int):Void {
		topDoor.y = 0;
		bottomDoor.y = 0;
		iconSprite.alpha = 1;

		waterMark.alpha = 1;
		eventText.alpha = 1;
		eventText.text = Language.getPhrase('trans_opening', 'Opening...');

		add(topDoor);
		add(bottomDoor);
		add(iconSprite);
		add(waterMark);
		add(eventText);

		try {
			FlxG.sound.play(Paths.sound('FadeTransition'), 0.4);
		} catch (e:Dynamic) {}

		topDoorTween = addTween(FlxTween.tween(topDoor, {y: -height}, duration, {
			ease: FlxEase.expoInOut,
			onStart: function(tween:FlxTween) {
				if (isValidTransition() && eventText != null)
					eventText.text = Language.getPhrase('trans_completed', 'Completed!');
			}
		}));

		bottomDoorTween = addTween(FlxTween.tween(bottomDoor, {y: height}, duration, {
			ease: FlxEase.expoInOut,
			onComplete: function(tween:FlxTween) {
				if (isValidTransition()) {
					safeClose();
				}
			}
		}));

		textTween = addTween(FlxTween.tween(waterMark, {y: waterMark.y + 100, alpha: 0}, duration, {
			ease: FlxEase.expoInOut
		}));

		addTween(FlxTween.tween(eventText, {y: eventText.y + 100, alpha: 0}, duration, {
			ease: FlxEase.expoInOut
		}));

		iconTween = addTween(FlxTween.tween(iconSprite, {alpha: 0}, duration, {
			ease: FlxEase.expoInOut
		}));
	}

	function createTransitionOut(width:Int, height:Int):Void {
		topDoor.y = -height;
		bottomDoor.y = height;
		iconSprite.alpha = 0;
		eventText.text = Language.getPhrase('trans_loading', 'Loading...');

		var originalWaterMarkY = height - 140;
		var originalEventTextY = height - 60;
		waterMark.y = originalWaterMarkY + 100;
		waterMark.alpha = 0;
		eventText.y = originalEventTextY + 100;
		eventText.alpha = 0;

		add(topDoor);
		add(bottomDoor);
		add(iconSprite);
		add(waterMark);
		add(eventText);

		textTween = addTween(FlxTween.tween(waterMark, {y: originalWaterMarkY, alpha: 1}, duration, {
			ease: FlxEase.expoInOut
		}));

		addTween(FlxTween.tween(eventText, {y: originalEventTextY, alpha: 1}, duration, {
			ease: FlxEase.expoInOut
		}));

		topDoorTween = addTween(FlxTween.tween(topDoor, {y: 0}, duration, {
			ease: FlxEase.expoInOut
		}));

		bottomDoorTween = addTween(FlxTween.tween(bottomDoor, {y: 0}, duration, {
			ease: FlxEase.expoInOut,
			onComplete: function(tween:FlxTween) {
				if (!isValidTransition()) return;

				iconTween = addTween(FlxTween.tween(iconSprite, {alpha: 1}, 0.3, {
					ease: FlxEase.sineIn,
					onComplete: function(tween:FlxTween) {
						if (isValidTransition()) {
							safeFinishCallback();
						}
					}
				}));
			}
		}));
	}

	function isValidTransition():Bool {
		return !isDestroyed && !isClosing && currentTransition == this;
	}

	function forceUnlock():Void {
		if (currentTransition == this) {
			isTransitioning = false;
			currentTransition = null;
		}

		finishCallback = null;
		cancelAllTweens();

		if (!isDestroyed) {
			forceClose();
		}
	}

	function forceClose():Void {
		if (isDestroyed || isClosing) return;

		isClosing = true;

		if (currentTransition == this) {
			isTransitioning = false;
			currentTransition = null;
		}

		cancelAllTweens();

		try {
			close();
		} catch (e:Dynamic) {}
	}

	function safeFinishCallback():Void {
		if (!isValidTransition()) return;

		if (currentTransition == this) {
			isTransitioning = false;
			currentTransition = null;
		}

		if (finishCallback != null) {
			var callback = finishCallback;
			finishCallback = null;
			try {
				callback();
			} catch (e:Dynamic) {}
		}
	}

	function safeClose():Void {
		if (!isValidTransition()) return;

		isClosing = true;

		if (!ClientPrefs.data.vanillaTransition) {
			if (currentTransition == this) {
				isTransitioning = false;
				currentTransition = null;
			}
		}

		cancelAllTweens();

		try {
			close();
		} catch (e:Dynamic) {}
	}

	function cancelAllTweens():Void {
		try {
			for (tween in activeTweens) {
				if (tween != null && !tween.finished) {
					tween.cancel();
				}
			}
			activeTweens = [];

			if (topDoorTween != null) {
				topDoorTween.cancel();
				topDoorTween = null;
			}
			if (bottomDoorTween != null) {
				bottomDoorTween.cancel();
				bottomDoorTween = null;
			}
			if (textTween != null) {
				textTween.cancel();
				textTween = null;
			}
			if (iconTween != null) {
				iconTween.cancel();
				iconTween = null;
			}
		} catch (e:Dynamic) {}
	}

	override function close() {
		if (isDestroyed) return;

		isDestroyed = true;
		isClosing = true;

		if (currentTransition == this) {
			isTransitioning = false;
			currentTransition = null;
		}

		try {
			cancelAllTweens();

			if (ClientPrefs.data.vanillaTransition && finishCallback != null) {
				var callback = finishCallback;
				finishCallback = null;
				callback();
			} else {
				finishCallback = null;
			}

			super.close();
		} catch (e:Dynamic) {
			isTransitioning = false;
			currentTransition = null;
		}
	}

	override function destroy() {
		if (isDestroyed) return;

		isDestroyed = true;
		isClosing = true;

		if (currentTransition == this) {
			isTransitioning = false;
			currentTransition = null;
		}

		try {
			cancelAllTweens();
			finishCallback = null;

			if (topDoor != null) {
				topDoor.destroy();
				topDoor = null;
			}
			if (bottomDoor != null) {
				bottomDoor.destroy();
				bottomDoor = null;
			}
			if (waterMark != null) {
				waterMark.destroy();
				waterMark = null;
			}
			if (eventText != null) {
				eventText.destroy();
				eventText = null;
			}
			if (iconSprite != null) {
				iconSprite.destroy();
				iconSprite = null;
			}
			if (transBlack != null) {
				transBlack.destroy();
				transBlack = null;
			}
			if (transGradient != null) {
				transGradient.destroy();
				transGradient = null;
			}

			super.destroy();
		} catch (e:Dynamic) {
			isTransitioning = false;
			currentTransition = null;
		}
	}
}

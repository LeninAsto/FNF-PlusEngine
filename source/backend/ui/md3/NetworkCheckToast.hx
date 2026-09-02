package backend.ui.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import backend.ui.md3.MaterialWavyProgressIndicator.WavyProgressType;

class NetworkCheckToast extends FlxSpriteGroup
{
	static inline var CARD_WIDTH:Int = 300;
	static inline var CARD_HEIGHT:Int = 72;
	static inline var CARD_X:Float = 24;
	static inline var SUCCESS_HIDE_DELAY:Float = 1.0;

	static var current:NetworkCheckToast;
	static var pendingMessage:String;
	static var pendingDoneMessage:String;
	static var pendingShows:Int = 0;
	static var pendingHides:Int = 0;
	static var activeChecks:Int = 0;

	var background:FlxSprite;
	var label:FlxText;
	var indicator:MaterialWavyProgressIndicator;
	var hideTween:FlxTween;
	var showTween:FlxTween;
	var hideDelay:Float = -1;

	public var cardX:Float = -CARD_WIDTH - 32;

	var cardY:Float = 0;

	public static function requestShow(message:String):Void
	{
		pendingMessage = message;
		pendingShows++;
	}

	public static function requestHide():Void
	{
		pendingHides++;
	}

	public static function requestDone(?message:String = 'Obtenido'):Void
	{
		pendingDoneMessage = message;
		pendingHides++;
	}

	public static function updateRequests():Void
	{
		if (pendingShows <= 0 && pendingHides <= 0 && pendingMessage == null && pendingDoneMessage == null)
			return;

		if (current != null && !current.exists)
			current = null;

		while (pendingShows > 0)
		{
			activeChecks++;
			pendingShows--;
		}

		while (pendingHides > 0)
		{
			activeChecks = Std.int(Math.max(0, activeChecks - 1));
			pendingHides--;
		}

		if (pendingMessage != null)
		{
			showNow(pendingMessage);
			pendingMessage = null;
		}

		if (pendingDoneMessage != null)
		{
			if (activeChecks <= 0)
			{
				showNow(pendingDoneMessage);
				if (current != null)
					current.hideDelay = SUCCESS_HIDE_DELAY;
			}
			pendingDoneMessage = null;
		}

		if (current != null && activeChecks <= 0)
		{
			if (current.hideDelay < 0)
				current.hideDelay = 0;
		}
	}

	static function showNow(message:String):Void
	{
		if (FlxG.state == null)
			return;

		if (current == null)
		{
			current = new NetworkCheckToast(message);
			FlxG.state.add(current);
		}
		else
			current.setMessage(message);

		current.show();
	}

	public function new(message:String)
	{
		super(0, 0);

		scrollFactor.set();
		cardY = (FlxG.height - CARD_HEIGHT) * 0.5;

		background = new FlxSprite();
		background.antialiasing = ClientPrefs.data.antialiasing;
		MD3ShapeTools.fillAndStrokeRoundRect(background, CARD_WIDTH, CARD_HEIGHT, 22, 2, MD3Theme.surfaceContainerHigh, MD3Theme.outlineVariant);
		add(background);

		indicator = new MaterialWavyProgressIndicator(0, 0, WavyProgressType.CIRCULAR, 38);
		indicator.indeterminate = true;
		indicator.setTrackColor(MD3Theme.surfaceVariant);
		indicator.setWaveColor(MD3Theme.primary);
		add(indicator);

		label = new FlxText(0, 0, CARD_WIDTH - 94, message, 18);
		label.setFormat(Paths.font('NotoSans-Medium.ttf'), 18, MD3Theme.onSurface, FlxTextAlign.LEFT);
		label.fieldWidth = CARD_WIDTH - 94;
		label.fieldHeight = CARD_HEIGHT;
		label.antialiasing = ClientPrefs.data.antialiasing;
		add(label);
		layoutCard();

		alpha = 0;
		visible = false;
		active = false;
	}

	function setMessage(message:String):Void
	{
		label.text = message;
		label.fieldWidth = CARD_WIDTH - 94;
		label.fieldHeight = CARD_HEIGHT;
		layoutCard();
	}

	function show():Void
	{
		if (hideTween != null)
			hideTween.cancel();

		hideDelay = -1;
		visible = true;
		active = true;
		cardY = (FlxG.height - CARD_HEIGHT) * 0.5;
		layoutCard();

		if (showTween != null)
			showTween.cancel();

		showTween = FlxTween.tween(this, {cardX: CARD_X, alpha: 1}, 0.22, {ease: FlxEase.quadOut});
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		layoutCard();
		if (hideDelay >= 0)
		{
			hideDelay -= elapsed;
			if (hideDelay <= 0)
			{
				hideDelay = -1;
				hide();
			}
		}
	}

	function hide():Void
	{
		if (!visible)
			return;

		if (showTween != null)
			showTween.cancel();
		if (hideTween != null)
			hideTween.cancel();

		hideTween = FlxTween.tween(this, {cardX: -CARD_WIDTH - 32, alpha: 0}, 0.18, {
			ease: FlxEase.quadIn,
			onComplete: function(_)
			{
				visible = false;
				active = false;
			}
		});
	}

	function layoutCard():Void
	{
		background.setPosition(cardX, cardY);
		indicator.setPosition(cardX + 20, cardY + 17);
		label.setPosition(cardX + 76, cardY + Math.floor((CARD_HEIGHT - 22) * 0.5));
	}

	override function destroy():Void
	{
		if (current == this)
			current = null;
		if (showTween != null)
			showTween.cancel();
		if (hideTween != null)
			hideTween.cancel();
		super.destroy();
	}
}


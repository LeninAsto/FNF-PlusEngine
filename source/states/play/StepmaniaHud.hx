package states.play;

import backend.Paths;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class StepmaniaHud
{
	public var scoreText(default, null):FlxText;
	public var accuracyText(default, null):FlxText;
	public var ratingText(default, null):FlxText;
	public var judgementSprite(default, null):FlxSprite;

	var judgementTween:FlxTween;

	public function new(uiGroup:FlxSpriteGroup, state:FlxState, hudCamera:FlxCamera, screenWidth:Float, screenHeight:Float, hideHud:Bool)
	{
		var centerY:Float = screenHeight / 2;

		scoreText = new FlxText(screenWidth - 320, centerY - 60, 300, "00000000", 48);
		scoreText.setFormat(Paths.font("aller.ttf"), 48, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreText.scrollFactor.set();
		scoreText.borderSize = 2;
		scoreText.visible = !hideHud;
		uiGroup.add(scoreText);

		accuracyText = new FlxText(screenWidth - 320, centerY, 300, "0.00%", 28);
		accuracyText.setFormat(Paths.font("aller.ttf"), 28, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		accuracyText.scrollFactor.set();
		accuracyText.borderSize = 1.5;
		accuracyText.visible = !hideHud;
		uiGroup.add(accuracyText);

		ratingText = new FlxText(screenWidth - 320, centerY + 35, 300, "?", 24);
		ratingText.setFormat(Paths.font("aller.ttf"), 24, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		ratingText.scrollFactor.set();
		ratingText.borderSize = 1.5;
		ratingText.visible = !hideHud;
		uiGroup.add(ratingText);

		judgementSprite = new FlxSprite();
		judgementSprite.cameras = [hudCamera];
		judgementSprite.visible = false;
		judgementSprite.alpha = 0;
		state.add(judgementSprite);
	}

	public function updateScore(songScore:Int, ratingPercent:Float, ratingName:String, ratingFC:String):Void
	{
		var scoreStr:String = Std.string(songScore);
		while (scoreStr.length < 8)
			scoreStr = '0' + scoreStr;

		scoreText.text = scoreStr;
		accuracyText.text = Std.string(backend.CoolUtil.floorDecimal(ratingPercent * 100, 2)) + '%';
		ratingText.text = ratingName + ' [' + ratingFC + ']';
	}

	public function showJudgement(ratingName:String, hideHud:Bool):Void
	{
		if (hideHud)
			return;

		var spriteName:String = switch(ratingName.toLowerCase())
		{
			case 'flawless': 'fantastic';
			case 'sick': 'excellent';
			case 'good': 'great';
			case 'bad': 'decent';
			case 'shit': 'way-off';
			default: ratingName.toLowerCase();
		};

		if (judgementTween != null)
		{
			judgementTween.cancel();
			judgementTween = null;
		}

		judgementSprite.loadGraphic(Paths.image('stepmania/' + spriteName));
		judgementSprite.setGraphicSize(Std.int(judgementSprite.width * 0.7));
		judgementSprite.updateHitbox();
		judgementSprite.screenCenter();
		judgementSprite.visible = true;
		judgementSprite.alpha = 1;
		judgementSprite.scale.set(1.3, 1.3);

		judgementTween = FlxTween.tween(judgementSprite.scale, {x: 1, y: 1}, 0.2, {
			ease: FlxEase.backOut
		});
	}

	public function destroyFrom(state:FlxState, uiGroup:FlxSpriteGroup):Void
	{
		uiGroup.remove(scoreText, true);
		uiGroup.remove(accuracyText, true);
		uiGroup.remove(ratingText, true);
		state.remove(judgementSprite);

		scoreText.destroy();
		accuracyText.destroy();
		ratingText.destroy();
		judgementSprite.destroy();
	}
}

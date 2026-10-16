package states.play;

#if windows
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.NumTween;
import flixel.util.FlxColor;
import objects.Note;
import slushithings.windows.WindowsAPI;

class WindowBorderPulse
{
	static final BASE:Array<Int> = [128, 41, 182];
	static var tween:NumTween;

	public static function hit(note:Note):Void
	{
		var color:FlxColor = FlxColor.WHITE;
		var palette:Array<FlxColor> = Note.getNoteColorPalette(note.noteData % 4, states.PlayState.isPixelStage);
		if (palette != null && palette.length > 0)
			color = palette[0];

		var target:Array<Int> = [color.red, color.green, color.blue];
		if (tween != null)
			tween.cancel();

		tween = FlxTween.num(0, 1, 0.1, {ease: FlxEase.cubeOut});
		tween.onUpdate = function(_) setLerp(BASE, target, tween.value);
		tween.onComplete = function(_)
		{
			tween = FlxTween.num(0, 1, 0.2, {ease: FlxEase.cubeInOut});
			tween.onUpdate = function(_) setLerp(target, BASE, tween.value);
			tween.onComplete = function(_) tween = null;
		};
	}

	static function setLerp(from:Array<Int>, to:Array<Int>, t:Float):Void
	{
		WindowsAPI.setWindowBorderColor(
			Std.int(from[0] + (to[0] - from[0]) * t),
			Std.int(from[1] + (to[1] - from[1]) * t),
			Std.int(from[2] + (to[2] - from[2]) * t)
		);
	}
}
#end

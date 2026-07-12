package backend;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxMath;

@:access(flixel.FlxGame)
class RenderInterpolation
{
	static var installed:Bool = false;

	public static function install():Void
	{
		if (installed)
			return;

		installed = true;
		FlxG.signals.preDraw.add(onPreDraw);
		FlxG.signals.postDraw.add(onPostDraw);
	}

	static function onPreDraw():Void
	{
		if (!FlxG.fixedTimestep || FlxG.game == null)
			return;

		var stepMS:Float = FlxG.game._stepMS;
		if (stepMS <= 0)
			return;

		var alpha:Float = FlxMath.bound(FlxG.game._accumulator / stepMS, 0, 1);
		for (camera in FlxG.cameras.list)
			applyCameraInterpolation(camera, alpha);
	}

	static function onPostDraw():Void
	{
		for (camera in FlxG.cameras.list)
			restoreCameraState(camera);
	}

	static function applyCameraInterpolation(camera:FlxCamera, alpha:Float):Void
	{
		if (camera != null && Std.isOfType(camera, PsychCamera))
			cast(camera, PsychCamera).applyRenderInterpolation(alpha);
	}

	static function restoreCameraState(camera:FlxCamera):Void
	{
		if (camera != null && Std.isOfType(camera, PsychCamera))
			cast(camera, PsychCamera).restoreSimulationState();
	}

	public static function syncAllCameras():Void
	{
		if (FlxG.cameras == null)
			return;

		for (camera in FlxG.cameras.list)
		{
			if (camera != null && Std.isOfType(camera, PsychCamera))
				cast(camera, PsychCamera).syncInterpolationState();
		}
	}
}

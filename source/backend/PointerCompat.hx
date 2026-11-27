package backend;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.input.FlxPointer;
import flixel.math.FlxPoint;

class PointerCompat
{
	public static function legacyScreenPosition(pointer:FlxPointer, ?camera:FlxCamera, ?result:FlxPoint):FlxPoint
	{
		if (camera == null) camera = FlxG.camera;
		final point = pointer.getViewPosition(camera, result);
		point.x += 0.5 * camera.width * (camera.zoom - camera.initialZoom) / camera.zoom;
		point.y += 0.5 * camera.height * (camera.zoom - camera.initialZoom) / camera.zoom;
		return point;
	}
}

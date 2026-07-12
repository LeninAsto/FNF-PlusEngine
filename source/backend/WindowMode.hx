package backend;

import openfl.Lib;
import openfl.system.Capabilities;

class WindowMode
{
	public static var borderlessFullscreen(default, null):Bool = false;
	public static var exclusiveFullscreen(default, null):Bool = false;

	static var lastWindowedX:Int = 0;
	static var lastWindowedY:Int = 0;
	static var lastWindowedW:Int = 0;
	static var lastWindowedH:Int = 0;
	static var hasWindowedState:Bool = false;

	public static function toggleBorderlessFullscreen():Void
	{
		setBorderlessFullscreen(!borderlessFullscreen);
	}

	public static function toggleFullscreen():Void
	{
		#if desktop
		#if windows
		var mode = ClientPrefs.data.fullscreenMode;
		if (mode == 'Exclusive')
			setExclusiveFullscreen(!exclusiveFullscreen);
		else if (mode == 'Borderless Fix')
			setBorderlessFullscreenFix(!borderlessFullscreen);
		else
			setBorderlessFullscreen(!borderlessFullscreen);
		#else
		setBorderlessFullscreen(!borderlessFullscreen);
		#end
		#end
	}

	public static function setExclusiveFullscreen(enable:Bool):Void
	{
		#if desktop
		var window = Lib.current.stage.window;
		if (window == null) return;

		if (enable)
		{
			if (!exclusiveFullscreen && !borderlessFullscreen)
			{
				lastWindowedX = window.x;
				lastWindowedY = window.y;
				lastWindowedW = window.width;
				lastWindowedH = window.height;
				hasWindowedState = true;
			}

			if (borderlessFullscreen)
			{
				window.borderless = false;
				borderlessFullscreen = false;
			}

			try {
				window.fullscreen = true;
			} catch (_:Dynamic) {}
		}
		else
		{
			window.fullscreen = false;
			if (hasWindowedState && lastWindowedW > 0 && lastWindowedH > 0)
			{
				window.resize(lastWindowedW, lastWindowedH);
				window.x = lastWindowedX;
				window.y = lastWindowedY;
			}
		}

		exclusiveFullscreen = enable;
		ClientPrefs.applyFramePacing();
		RenderInterpolation.syncAllCameras();
		#end
	}

	public static function setBorderlessFullscreen(enable:Bool):Void
	{
		#if desktop
		var window = Lib.current.stage.window;
		if (window == null) return;

		if (enable)
		{
			if (!borderlessFullscreen && !exclusiveFullscreen)
			{
				lastWindowedX = window.x;
				lastWindowedY = window.y;
				lastWindowedW = window.width;
				lastWindowedH = window.height;
				hasWindowedState = true;
			}

			if (exclusiveFullscreen)
			{
				try {
					window.fullscreen = false;
				} catch (_:Dynamic) {}
				exclusiveFullscreen = false;
			}

			// Keep this mode as a regular bordered window (dev behavior).
			// Borderless Fix is the one that becomes true borderless fullscreen.
			try {
				window.fullscreen = false;
			} catch (_:Dynamic) {}
			window.borderless = false;

			var screenW = Std.int(Capabilities.screenResolutionX);
			var screenH = Std.int(Capabilities.screenResolutionY);
			var targetW = Std.int(Math.min(1980, screenW));
			var targetH = Std.int(Math.min(1080, screenH));

			window.resize(targetW, targetH);
			window.x = Std.int((screenW - targetW) * 0.5);
			window.y = Std.int((screenH - targetH) * 0.5);
		}
		else
		{
			window.borderless = false;
			if (hasWindowedState && lastWindowedW > 0 && lastWindowedH > 0)
			{
				window.resize(lastWindowedW, lastWindowedH);
				window.x = lastWindowedX;
				window.y = lastWindowedY;
			}
		}

		borderlessFullscreen = enable;
		ClientPrefs.applyFramePacing();
		RenderInterpolation.syncAllCameras();
		#end
	}

	public static function setBorderlessFullscreenFix(enable:Bool):Void
	{
		#if desktop
		var window = Lib.current.stage.window;
		if (window == null) return;

		if (enable)
		{
			if (!borderlessFullscreen && !exclusiveFullscreen)
			{
				lastWindowedX = window.x;
				lastWindowedY = window.y;
				lastWindowedW = window.width;
				lastWindowedH = window.height;
				hasWindowedState = true;
			}

			if (exclusiveFullscreen)
			{
				try {
					window.fullscreen = false;
				} catch (_:Dynamic) {}
				exclusiveFullscreen = false;
			}

			try {
				window.fullscreen = false;
			} catch (_:Dynamic) {}
			window.borderless = true;

			var screenW = Std.int(Capabilities.screenResolutionX);
			var screenH = Std.int(Capabilities.screenResolutionY);

			window.x = 0;
			window.y = 0;
			window.resize(screenW, screenH);
		}
		else
		{
			window.borderless = false;
			if (hasWindowedState && lastWindowedW > 0 && lastWindowedH > 0)
			{
				window.resize(lastWindowedW, lastWindowedH);
				window.x = lastWindowedX;
				window.y = lastWindowedY;
			}
		}

		borderlessFullscreen = enable;
		ClientPrefs.applyFramePacing();
		RenderInterpolation.syncAllCameras();
		#end
	}

	public static function updateWindowedSize(width:Int, height:Int):Void
	{
		if (hasWindowedState)
		{
			lastWindowedW = width;
			lastWindowedH = height;
		}
	}
}

package slushithings.windows;

import sys.*;
import sys.io.File;
#if windows
import flixel.tweens.FlxTween;
import flixel.tweens.misc.NumTween;
import lime.app.Application;
import lime.system.System;
import slushithings.windows.WindowsCPP;
import slushithings.windows.winGDIThings.SlushiWinGDI;
import slushithings.windows.winGDIThings.WinGDIThread;
import psychlua.LuaUtils;
#end

/**
 * API wrapper for Windows native functionality
 * Based on Slushi Engine implementation with improvements
 */
class WindowsAPI
{
	#if windows
	static var closingTween:NumTween;
	static var isClosing:Bool = false;
	static var windowBorderColorTween:NumTween;
	
	@:noPrivateAccess
	private static var _windowsWallpaperPath:String = null;
	public static var changedWallpaper:Bool = false;
	private static final savedWallpaperPath:String = "assets/cache/savedWindowswallpaper.png";
	#end

	/**
	 * Captures a screenshot and saves it to the specified path
	 * @param path Absolute path where to save the screenshot
	 */
	public static function capture(path:String):Void
	{
		#if windows
		WindowsCPP.captureGameWindow(path);
		#else
		trace("[Screenshot]: Screenshot capture is only available on Windows");
		#end
	}

	/**
	 * Sets the window as layered to enable transparency effects
	 * Must be called before using setWindowOppacity
	 */
	public static function setWindowLayered():Void
	{
		#if windows
		WindowsCPP.setWindowLayered();
		#else
		trace("Window transparency is only available on Windows");
		#end
	}

	/**
	 * Sets the window opacity/transparency
	 * @param alpha Alpha value from 0.0 (fully transparent) to 1.0 (fully opaque)
	 */
	public static function setWindowOppacity(alpha:Float):Void
	{
		#if windows
		WindowsCPP.setWindowAlpha(alpha);
		#else
		trace("Window transparency is only available on Windows");
		#end
	}

	/**
	 * Gets the current window opacity/transparency
	 * @return Alpha value from 0.0 (fully transparent) to 1.0 (fully opaque)
	 */
	public static function getWindowOppacity():Float
	{
		#if windows
		return WindowsCPP.getWindowAlpha();
		#else
		trace("Window transparency is only available on Windows");
		return 1.0;
		#end
	}

	public static function fadeOutAndExit(duration:Float = 0.6, exitCode:Int = 0):Void
	{
		#if windows
		if (isClosing)
		{
			return;
		}

		isClosing = true;
		Application.current.window.onClose.cancel();

		if (closingTween != null)
		{
			closingTween.cancel();
		}

		var startAlpha:Float = 1.0; // Window always starts fully opaque

		var tween:NumTween = FlxTween.num(startAlpha, 0, duration, {
			onComplete: function(twn:FlxTween)
			{
				closingTween = null;
				isClosing = false;
				Sys.exit(exitCode);
			}
		});
		
		tween.onUpdate = function(twn:FlxTween)
		{
			setWindowOppacity(tween.value);
		};

		closingTween = tween;
		#else
		Sys.exit(exitCode);
		#end
	}

	/**
	 * Sets the window border color (Windows 11 only)
	 * @param r Red component (0-255)
	 * @param g Green component (0-255)
	 * @param b Blue component (0-255)
	 */
	public static function setWindowBorderColor(r:Int, g:Int, b:Int):Void
	{
		#if windows
		WindowsCPP.setWindowBorderColor(r, g, b);
		#else
		trace("Window border color is only available on Windows");
		#end
	}

	// === Wallpaper Management Functions ===

	/**
	 * Changes the Windows wallpaper
	 * @param path Path to the wallpaper image (relative to assets folder)
	 */
	public static function changeWindowsWallpaper(path:String):Void
	{
		#if windows
		var allPath:String = Sys.getCwd() + 'assets/' + path;
		WindowsCPP.setWallpaper(allPath);
		changedWallpaper = true;
		trace("Wallpaper changed to: " + allPath);
		#else
		trace("Wallpaper change is only available on Windows");
		#end
	}

	/**
	 * Saves the current Windows wallpaper path
	 */
	public static function saveCurrentWindowsWallpaper():Void
	{
		#if windows
		var path = '${Sys.getEnv("AppData")}\\Microsoft\\Windows\\Themes\\TranscodedWallpaper';
		if (path != null)
		{
			trace("Wallpaper Path: " + path);
			trace("Saving the path in a private variable...");
			_windowsWallpaperPath = path;
		}
		else
		{
			trace("[ERROR]: Could not save the wallpaper path!");
		}
		#else
		trace("This function is only available on Windows");
		#end
	}

	/**
	 * Saves a copy of the current Windows wallpaper
	 */
	public static function saveCopyOfSavedWindowsWallpaper():Void
	{
		#if windows
		var finalPath = savedWallpaperPath;
		try
		{
			File.copy(_windowsWallpaperPath, finalPath);
			trace("Saved a copy of the wallpaper");
		}
		catch (e)
		{
			trace("[ERROR]: Could not save the wallpaper path: " + e);
		}
		#else
		trace("This function is only available on Windows");
		#end
	}

	/**
	 * Restores the old Windows wallpaper
	 */
	public static function setOldWindowsWallpaper():Void
	{
		#if windows
		if (!changedWallpaper)
			return;

		changedWallpaper = false;

		if (sys.FileSystem.exists(savedWallpaperPath))
		{
			var finalPath = savedWallpaperPath;
			WindowsCPP.setWallpaper(finalPath);
			trace("Wallpaper changed to: " + finalPath);
			return;
		}

		if (_windowsWallpaperPath != null)
		{
			WindowsCPP.setWallpaper(_windowsWallpaperPath);
			trace("Wallpaper changed to: " + _windowsWallpaperPath);
		}
		#else
		trace("This function is only available on Windows");
		#end
	}

	// === System Information Functions ===

	/**
	 * Gets the Windows version
	 * @return Windows version number (7, 8, 10, 11) or 0 if unknown
	 */
	public static function getWindowsVersion():Int
	{
		#if windows
		var windowsVersions:Map<String, Int> = [
			"Windows 11" => 11,
			"Windows 10" => 10,
			"Windows 8.1" => 8,
			"Windows 8" => 8,
			"Windows 7" => 7,
		];

		var platformLabel = System.platformLabel;
		var words = platformLabel.split(" ");
		var windowsIndex = words.indexOf("Windows");
		var result = "";
		if (windowsIndex != -1 && windowsIndex < words.length - 1)
		{
			result = words[windowsIndex] + " " + words[windowsIndex + 1];
		}

		if (windowsVersions.exists(result))
		{
			return windowsVersions.get(result);
		}
		return 0;
		#else
		return 0;
		#end
	}

	/**
	 * Gets the total physical RAM installed in the system (in MB)
	 * @return Total RAM in megabytes
	 */
	public static function getTotalSystemRAM():Int
	{
		#if windows
		return WindowsCPP.getTotalSystemRAM();
		#else
		trace("System memory info is only available on Windows");
		return 0;
		#end
	}

	/**
	 * Gets the available (free) physical RAM (in MB)
	 * @return Available RAM in megabytes
	 */
	public static function getAvailableRAM():Int
	{
		#if windows
		return WindowsCPP.getAvailableSystemRAM();
		#else
		trace("System memory info is only available on Windows");
		return 0;
		#end
	}

	/**
	 * Gets the memory usage percentage (0-100)
	 * @return Percentage of RAM currently in use
	 */
	public static function getMemoryUsagePercentage():Int
	{
		#if windows
		return WindowsCPP.getMemoryLoadPercentage();
		#else
		trace("System memory info is only available on Windows");
		return 0;
		#end
	}

	/**
	 * Gets the number of CPU cores
	 * @return Number of logical processors
	 */
	public static function getCPUCoreCount():Int
	{
		#if windows
		return WindowsCPP.getCPUCoreCount();
		#else
		trace("CPU info is only available on Windows");
		return 0;
		#end
	}

	/**
	 * Sends a Windows notification (Windows 8+)
	 * @param desc Description text
	 * @param title Title text
	 */
	public static function sendWindowsNotification(desc:String, title:String):Void
	{
		#if windows
		if (getWindowsVersion() < 8) return;

		var powershellCommand = "powershell -Command \"& {$ErrorActionPreference = 'Stop';"
			+ "$title = '"
			+ desc
			+ "';"
			+ "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null;"
			+ "$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText01);"
			+ "$toastXml = [xml] $template.GetXml();"
			+ "$toastXml.GetElementsByTagName('text').AppendChild($toastXml.CreateTextNode($title)) > $null;"
			+ "$xml = New-Object Windows.Data.Xml.Dom.XmlDocument;"
			+ "$xml.LoadXml($toastXml.OuterXml);"
			+ "$toast = [Windows.UI.Notifications.ToastNotification]::new($xml);"
			+ "$toast.Tag = 'Test1';"
			+ "$toast.Group = 'Test2';"
			+ "$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('"
			+ "Plus Engine: "
			+ title
			+ "');"
			+ "$notifier.Show($toast);}\"";

		if (title != null && title != "" && desc != null && desc != "")
		{
			new sys.io.Process(powershellCommand);
		}
		#else
		trace("Notifications are only available on Windows");
		#end
	}

	// === Desktop Control Functions ===

	/**
	 * Hides or shows the desktop icons
	 * @param hide True to hide, false to show
	 */
	public static function hideDesktopIcons(hide:Bool):Void
	{
		#if windows
		WindowsCPP.hideDesktopIcons(hide);
		#else
		trace("Desktop icons control is only available on Windows");
		#end
	}

	/**
	 * Hides or shows the taskbar
	 * @param hide True to hide, false to show
	 */
	public static function hideTaskBar(hide:Bool):Void
	{
		#if windows
		WindowsCPP.hideTaskbar(hide);
		#else
		trace("Taskbar control is only available on Windows");
		#end
	}

	/**
	 * Moves desktop icons position
	 * @param x X position
	 * @param y Y position
	 */
	public static function moveDesktopElements(x:Int, y:Int):Void
	{
		#if windows
		WindowsCPP.moveDesktopWindowsInXY(x, y);
		#else
		trace("Desktop elements control is only available on Windows");
		#end
	}

	/**
	 * Gets the X position of desktop icons
	 * @return X position
	 */
	public static function getDesktopWindowsXPos():Int
	{
		#if windows
		return WindowsCPP.getDesktopWindowsXPos();
		#else
		trace("Desktop elements control is only available on Windows");
		return 0;
		#end
	}

	/**
	 * Gets the Y position of desktop icons
	 * @return Y position
	 */
	public static function getDesktopWindowsYPos():Int
	{
		#if windows
		return WindowsCPP.getDesktopWindowsYPos();
		#else
		trace("Desktop elements control is only available on Windows");
		return 0;
		#end
	}

	/**
	 * Sets the transparency of desktop icons
	 * @param alpha Alpha value from 0.0 (fully transparent) to 1.0 (fully opaque)
	 */
	public static function setDesktopTransparency(alpha:Float):Void
	{
		#if windows
		WindowsCPP.setWindowLayeredMode(0);
		WindowsCPP.setDesktopWindowsAlpha(alpha);
		#else
		trace("Desktop transparency is only available on Windows");
		#end
	}

	/**
	 * Sets the transparency of the taskbar
	 * @param alpha Alpha value from 0.0 (fully transparent) to 1.0 (fully opaque)
	 */
	public static function setTaskBarTransparency(alpha:Float):Void
	{
		#if windows
		WindowsCPP.setWindowLayeredMode(1);
		WindowsCPP.setTaskBarAlpha(alpha);
		#else
		trace("Taskbar transparency is only available on Windows");
		#end
	}

	// === Tween Functions ===

	/**
	 * Tweens desktop icons position in X axis
	 * @param toValue Target X position
	 * @param duration Duration in seconds
	 * @param ease Easing function name
	 */
	public static function doTweenDesktopWindowsX(toValue:Float, duration:Float, ease:String = "linear"):Void
	{
		#if windows
		var startValue = WindowsCPP.getDesktopWindowsXPos();
		var numTween:NumTween = FlxTween.num(startValue, toValue, duration, {ease: LuaUtils.getTweenEaseByString(ease)});
		numTween.onUpdate = function(twn:FlxTween)
		{
			WindowsCPP.moveDesktopWindowsInX(Std.int(numTween.value));
		}
		#else
		trace("Desktop tweens are only available on Windows");
		#end
	}

	/**
	 * Tweens desktop icons position in Y axis
	 * @param toValue Target Y position
	 * @param duration Duration in seconds
	 * @param ease Easing function name
	 */
	public static function doTweenDesktopWindowsY(toValue:Float, duration:Float, ease:String = "linear"):Void
	{
		#if windows
		var startValue = WindowsCPP.getDesktopWindowsYPos();
		var numTween:NumTween = FlxTween.num(startValue, toValue, duration, {ease: LuaUtils.getTweenEaseByString(ease)});
		numTween.onUpdate = function(twn:FlxTween)
		{
			WindowsCPP.moveDesktopWindowsInY(Std.int(numTween.value));
		}
		#else
		trace("Desktop tweens are only available on Windows");
		#end
	}

	/**
	 * Tweens desktop icons transparency
	 * @param fromValue Starting alpha value
	 * @param toValue Target alpha value
	 * @param duration Duration in seconds
	 * @param ease Easing function name
	 */
	public static function doTweenDesktopWindowsAlpha(fromValue:Float, toValue:Float, duration:Float, ease:String = "linear"):Void
	{
		#if windows
		var numTween:NumTween = FlxTween.num(fromValue, toValue, duration, {ease: LuaUtils.getTweenEaseByString(ease)});
		numTween.onUpdate = function(twn:FlxTween)
		{
			WindowsCPP.setDesktopWindowsAlpha(numTween.value);
		}
		#else
		trace("Desktop tweens are only available on Windows");
		#end
	}

	/**
	 * Tweens taskbar transparency
	 * @param fromValue Starting alpha value
	 * @param toValue Target alpha value
	 * @param duration Duration in seconds
	 * @param ease Easing function name
	 */
	public static function doTweenTaskBarAlpha(fromValue:Float, toValue:Float, duration:Float, ease:String = "linear"):Void
	{
		#if windows
		var numTween:NumTween = FlxTween.num(fromValue, toValue, duration, {ease: LuaUtils.getTweenEaseByString(ease)});
		numTween.onUpdate = function(twn:FlxTween)
		{
			WindowsCPP.setTaskBarAlpha(numTween.value);
		}
		#else
		trace("Taskbar tweens are only available on Windows");
		#end
	}

	/**
	 * Tweens window border color (Windows 11 only)
	 * @param fromColor Starting RGB color array [r, g, b]
	 * @param toColor Target RGB color array [r, g, b]
	 * @param duration Duration in seconds
	 * @param ease Easing function name
	 */
	public static function tweenWindowBorderColor(fromColor:Array<Int>, toColor:Array<Int>, duration:Float, ease:String = "linear"):Void
	{
		#if windows
		if (getWindowsVersion() != 11)
		{
			trace("Border color tweening is only available on Windows 11");
			return;
		}

		if (windowBorderColorTween != null)
		{
			windowBorderColorTween.cancel();
		}

		windowBorderColorTween = FlxTween.num(0, 1, duration, {
			ease: LuaUtils.getTweenEaseByString(ease)
		});

		var startColor:Array<Int> = fromColor;
		var targetColor:Array<Int> = toColor;

		windowBorderColorTween.onUpdate = function(tween:FlxTween)
		{
			var interpolatedColor:Array<Int> = [];
			for (i in 0...3)
			{
				var newValue:Int = startColor[i] + Std.int((targetColor[i] - startColor[i]) * windowBorderColorTween.value);
				newValue = Std.int(Math.max(0, Math.min(255, newValue)));
				interpolatedColor.push(newValue);
			}
			WindowsCPP.setWindowBorderColor(interpolatedColor[0], interpolatedColor[1], interpolatedColor[2]);
		};
		#else
		trace("Border color tweening is only available on Windows");
		#end
	}

	/**
	 * Sets window border color from an integer color value (Windows 11 only)
	 * @param color Color as integer (0xRRGGBB)
	 */
	public static function setWindowBorderColorFromInt(color:Int):Void
	{
		#if windows
		if (getWindowsVersion() != 11)
		{
			trace("Border color is only available on Windows 11");
			return;
		}

		var red:Int = (color >> 16) & 0xFF;
		var green:Int = (color >> 8) & 0xFF;
		var blue:Int = color & 0xFF;
		WindowsCPP.setWindowBorderColor(red, green, blue);
		#else
		trace("Border color is only available on Windows");
		#end
	}

	/**
	 * Cancels the window border color tween
	 */
	public static function cancelWindowBorderColorTween():Void
	{
		#if windows
		if (windowBorderColorTween != null)
		{
			windowBorderColorTween.cancel();
			windowBorderColorTween = null;
		}
		#end
	}

	// === System Reset Functions ===

	/**
	 * Resets all Windows changes made by the API
	 */
	public static function resetAllCPPFunctions():Void
	{
		#if windows
		WindowsCPP.hideTaskbar(false);
		WindowsCPP.hideDesktopIcons(false);
		WindowsCPP.moveDesktopWindowsInXY(0, 0);
		WindowsCPP.setTaskBarAlpha(1);
		WindowsCPP.setDesktopWindowsAlpha(1);

		if (changedWallpaper)
		{
			setOldWindowsWallpaper();
		}
		#else
		trace("Reset functions are only available on Windows");
		#end
	}

	// === GDI Effects Functions ===

	/**
	 * Initializes the Windows GDI effects thread
	 */
	public static function initGDIThread():Void
	{
		#if windows
		WinGDIThread.initWindowsGDIThread();
		#else
		trace("GDI effects are only available on Windows");
		#end
	}

	/**
	 * Stops the Windows GDI effects thread
	 */
	public static function stopGDIThread():Void
	{
		#if windows
		WinGDIThread.stopWindowsGDIThread();
		#else
		trace("GDI effects are only available on Windows");
		#end
	}

	/**
	 * Pauses or resumes the GDI effects thread
	 * @param pause True to pause, false to resume
	 */
	public static function pauseGDIThread(pause:Bool):Void
	{
		#if windows
		WinGDIThread.temporarilyPaused = pause;
		#else
		trace("GDI effects are only available on Windows");
		#end
	}

	/**
	 * Checks if the GDI thread is running
	 * @return True if running, false otherwise
	 */
	public static function isGDIThreadRunning():Bool
	{
		#if windows
		return WinGDIThread.runningThread;
		#else
		trace("GDI effects are only available on Windows");
		return false;
		#end
	}

	/**
	 * Gets the elapsed time of the GDI thread
	 * @return Elapsed time in frames
	 */
	public static function getGDIElapsedTime():Float
	{
		#if windows
		return WinGDIThread.elapsedTime;
		#else
		trace("GDI effects are only available on Windows");
		return 0;
		#end
	}

	/**
	 * Prepares a GDI effect for use
	 * @param effect Effect name (DrawIcons, ScreenBlink, ScreenGlitches, ScreenShake, ScreenTunnel, SetTitleTextToWindows)
	 * @param wait Wait time between effect executions (in seconds)
	 */
	public static function prepareGDIEffect(effect:String, wait:Float = 0):Void
	{
		#if windows
		SlushiWinGDI.prepareGDIEffect(effect, wait);
		#else
		trace("GDI effects are only available on Windows");
		#end
	}

	/**
	 * Enables or disables a prepared GDI effect
	 * @param effect Effect name
	 * @param enabled True to enable, false to disable
	 */
	public static function enableGDIEffect(effect:String, enabled:Bool = true):Void
	{
		#if windows
		SlushiWinGDI.enableGDIEffect(effect, enabled);
		#else
		trace("GDI effects are only available on Windows");
		#end
	}

	/**
	 * Removes a GDI effect
	 * @param effect Effect name
	 */
	public static function removeGDIEffect(effect:String):Void
	{
		#if windows
		SlushiWinGDI.removeGDIEffect(effect);
		#else
		trace("GDI effects are only available on Windows");
		#end
	}

	/**
	 * Sets the wait time for a GDI effect
	 * @param effect Effect name
	 * @param wait Wait time in seconds
	 */
	public static function setGDIEffectWaitTime(effect:String, wait:Float):Void
	{
		#if windows
		SlushiWinGDI.setGDIEffectWaitTime(effect, wait);
		#else
		trace("GDI effects are only available on Windows");
		#end
	}

	/**
	 * Sets the elapsed time of the GDI thread (for synchronization)
	 * @param elapsed Elapsed time in frames
	 */
	public static function setGDIElapsedTime(elapsed:Float):Void
	{
		#if windows
		SlushiWinGDI.setElapsedTime(elapsed);
		#else
		trace("GDI effects are only available on Windows");
		#end
	}
}
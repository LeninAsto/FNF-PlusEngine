package slushithings.windows.winGDIThings;

import sys.thread.Thread;
import states.PlayState;

/**
 * This class starts an external thread to the main one of the engine, it is used so that 
 * Windows GDI effects do not generate lag in the game due to the fact that they consume quite some resources
 * Based on Slushi Engine implementation
 * 
 * Author: Slushi
 */
class WinGDIThread
{
	public static var mainThread:Thread;
	public static var gdiEffects:Map<String, SlushiWinGDIEffectData> = [];
	public static var runningThread:Bool = true;
	public static var elapsedTime:Float = 0;
	public static var temporarilyPaused:Bool = false;

	public static function initWindowsGDIThread()
	{
		#if windows
		if (mainThread != null)
		{
			trace("[WinGDIThread]: Thread already running");
			return;
		}

		trace('[WinGDIThread]: Starting Windows GDI Thread...');

		mainThread = Thread.create(() ->
		{
			trace('[WinGDIThread]: Windows GDI Thread running...');
			runningThread = true;
			
			while (runningThread)
			{
				/**
				 * Check if the game is focused or if the PlayState is paused or the player is dead
				 * This prevents GDI effects from continuing to be generated at times when they should not be
				 */
				if (!Main.focused)
				{
					continue;
				}
				if (PlayState.instance != null)
				{
					if (PlayState.instance.paused)
					{
						continue;
					}
					else if (PlayState.instance.isDead)
					{
						continue;
					}
				}
				if (temporarilyPaused)
				{
					continue;
				}

				elapsedTime++;
				SlushiWinGDI.setElapsedTime(elapsedTime);

				for (gdi in gdiEffects)
				{
					if (!gdi.enabled)
						continue;

					if (gdi.wait > 0)
					{
						// Wait if wait time is greater than 0, slows down the effect
						Sys.sleep(gdi.wait);
					}
					gdi.gdiEffect.update();
				}
			}
			trace('[WinGDIThread]: Windows GDI Thread stopped');
		});
		#end
	}

	public static function stopWindowsGDIThread()
	{
		#if windows
		if (mainThread != null)
		{
			trace('[WinGDIThread]: Stopping Windows GDI Thread...');
			runningThread = false;
			temporarilyPaused = false;
			mainThread = null;
		}
		gdiEffects.clear();
		elapsedTime = 0;
		SlushiWinGDI.setElapsedTime(elapsedTime);
		#end
	}
}

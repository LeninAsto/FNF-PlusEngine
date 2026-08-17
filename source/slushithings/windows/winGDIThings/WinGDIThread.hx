package slushithings.windows.winGDIThings;

import sys.thread.Thread;
import sys.thread.Mutex;
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
	public static var effectsMutex:Mutex = new Mutex();
	public static var runningThread:Bool = false;
	public static var elapsedTime:Float = 0;
	public static var temporarilyPaused:Bool = false;

	static inline var IDLE_SLEEP:Float = 0.01;

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
					Sys.sleep(IDLE_SLEEP);
					continue;
				}
				if (PlayState.instance != null)
				{
					if (PlayState.instance.paused)
					{
						Sys.sleep(IDLE_SLEEP);
						continue;
					}
					else if (PlayState.instance.isDead)
					{
						Sys.sleep(IDLE_SLEEP);
						continue;
					}
				}
				if (temporarilyPaused)
				{
					Sys.sleep(IDLE_SLEEP);
					continue;
				}

				elapsedTime++;
				SlushiWinGDI.setElapsedTime(elapsedTime);

				effectsMutex.acquire();
				var effects:Array<SlushiWinGDIEffectData> = [for (gdi in gdiEffects) gdi];
				effectsMutex.release();

				if (effects.length == 0)
				{
					Sys.sleep(IDLE_SLEEP);
					continue;
				}

				var ranEffect:Bool = false;
				for (gdi in effects)
				{
					if (!gdi.enabled)
						continue;

					if (gdi.wait > 0)
					{
						// Wait if wait time is greater than 0, slows down the effect
						Sys.sleep(gdi.wait);
					}
					gdi.gdiEffect.update();
					ranEffect = true;
				}

				if (!ranEffect)
					Sys.sleep(IDLE_SLEEP);
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
		effectsMutex.acquire();
		gdiEffects.clear();
		effectsMutex.release();
		elapsedTime = 0;
		SlushiWinGDI.setElapsedTime(elapsedTime);
		#end
	}
}


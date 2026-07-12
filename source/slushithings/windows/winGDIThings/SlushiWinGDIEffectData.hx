package slushithings.windows.winGDIThings;

import slushithings.windows.winGDIThings.SlushiWinGDI.SlushiWinGDIEffect;

/**
 * Simple class that contains data from the GDI effect before it is started
 * Based on Slushi Engine implementation
 * 
 * Author: Slushi
 */
class SlushiWinGDIEffectData
{
	public var gdiEffect:SlushiWinGDIEffect;
	public var wait:Float = 0;
	public var enabled:Bool = false;

	public function new(_gdiEffect:SlushiWinGDIEffect, _wait:Float = 0, _enabled:Bool = false)
	{
		this.gdiEffect = _gdiEffect;
		this.wait = _wait;
		this.enabled = _enabled;
	}
}

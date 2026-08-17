package backend;

import flixel.FlxG;
import flixel.FlxObject;

/**
 * Additional utilities for FlxG to ensure compatibility with older mods
 */
class FlxGUtils
{
	/**
	 * Adds support for addChildBelowMouse from previous versions
	 */
	public static function addChildBelowMouse(object:FlxObject, ?IndexModifier:Int = 0):Void
	{
		// In the current engine, we simply add to the state
		FlxG.state.add(object);
	}

	/**
	 * Support for removeChild
	 */
	public static function removeChild(object:FlxObject):Void
	{
		if (FlxG.state.members.contains(object))
			FlxG.state.remove(object);
	}
}


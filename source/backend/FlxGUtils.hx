package backend;

import flixel.FlxG;
import flixel.FlxObject;

/**
 * Utilidades adicionales para FlxG para compatibilidad con mods antiguos
 */
class FlxGUtils 
{
	/**
	 * Añade compatibilidad con addChildBelowMouse de versiones anteriores
	 */
	public static function addChildBelowMouse(object:FlxObject, ?IndexModifier:Int = 0):Void 
	{
		// En el engine actual, simplemente añadimos al state
		FlxG.state.add(object);
	}

	/**
	 * Compatibilidad con removeChild
	 */
	public static function removeChild(object:FlxObject):Void 
	{
		if (FlxG.state.members.contains(object))
			FlxG.state.remove(object);
	}
}

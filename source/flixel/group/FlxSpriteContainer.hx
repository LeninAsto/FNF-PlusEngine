package flixel.group;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

/**
 * Compatibility shim for VSlice source on Plus Engine's current Flixel.
 * Flixel 5.7+ provides FlxSpriteContainer; older forks only have
 * FlxSpriteGroup. VSlice only needs the typed grouped-sprite API here.
 */
typedef FlxSpriteContainer = FlxTypedSpriteContainer<FlxSprite>;

class FlxTypedSpriteContainer<T:FlxSprite> extends FlxTypedSpriteGroup<T>
{
	public function new(X:Float = 0, Y:Float = 0, MaxSize:Int = 0)
	{
		super(X, Y, MaxSize);
	}
}


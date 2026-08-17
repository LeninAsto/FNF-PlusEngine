package funkin.audio.visualize;

import funkin.graphics.FunkinSprite;

/**
 * Compatibility wrapper for VSlice mods that instantiate the old A-Bot atlas
 * class directly from HScript.
 */
@:nullSafety
class ABotAtlasSprite extends FunkinSprite
{
	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);
		loadTextureAtlas('characters/abot/abotSystem', 'shared');
	}
}


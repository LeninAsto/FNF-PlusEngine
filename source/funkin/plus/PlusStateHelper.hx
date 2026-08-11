package funkin.plus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxSort;

/**
 * Small compatibility helpers for VSlice modules that want to decorate Plus UI
 * states without depending on the official VSlice menu classes.
 */
class PlusStateHelper
{
	public static function currentState():FlxState
	{
		return FlxG.state;
	}

	public static function isPlusMainMenu(?state:Dynamic):Bool
	{
		return Std.isOfType(state ?? FlxG.state, states.MainMenuState);
	}

	public static function plusMainMenu(?state:Dynamic):Null<states.MainMenuState>
	{
		var target:Dynamic = state ?? FlxG.state;
		return Std.isOfType(target, states.MainMenuState) ? cast target : null;
	}

	public static function addToCurrentState(sprite:FlxSprite):FlxSprite
	{
		if (FlxG.state != null && sprite != null) FlxG.state.add(sprite);
		return sprite;
	}

	public static function addMainMenuAccessory(sprite:FlxSprite, slot:String = 'rightTop', index:Int = 0):FlxSprite
	{
		var state = plusMainMenu();
		if (state == null || sprite == null) return sprite;

		positionMainMenuAccessory(sprite, slot, index);
		state.add(sprite);
		return sprite;
	}

	public static function positionMainMenuAccessory(sprite:FlxSprite, slot:String = 'rightTop', index:Int = 0):Void
	{
		if (sprite == null) return;

		sprite.updateHitbox();
		var margin:Float = 28;
		var gap:Float = 14;
		var safeTop:Float = 84;
		var safeBottom:Float = FlxG.height - 110;

		switch (slot)
		{
			case 'leftTop':
				sprite.x = margin;
				sprite.y = safeTop + index * (sprite.height + gap);
			case 'leftBottom':
				sprite.x = margin;
				sprite.y = safeBottom - sprite.height - index * (sprite.height + gap);
			case 'rightBottom':
				sprite.x = FlxG.width - sprite.width - margin;
				sprite.y = safeBottom - sprite.height - index * (sprite.height + gap);
			default:
				sprite.x = FlxG.width - sprite.width - margin;
				sprite.y = safeTop + index * (sprite.height + gap);
		}
	}

	public static function setMainMenuInputEnabled(enabled:Bool):Void
	{
		var state = plusMainMenu();
		if (state == null || state.menuItems == null) return;

		state.menuItems.active = enabled;
		Reflect.setField(state.menuItems, 'enabled', enabled);
		Reflect.setField(state.menuItems, 'busy', !enabled);
	}

	public static function isMainMenuInputBlocked():Bool
	{
		var state = plusMainMenu();
		if (state == null || state.menuItems == null) return false;

		return Reflect.field(state.menuItems, 'enabled') == false || Reflect.field(state.menuItems, 'busy') == true;
	}

}

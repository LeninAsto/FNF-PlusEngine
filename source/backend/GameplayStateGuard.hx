package backend;

import flixel.FlxG;
import flixel.util.FlxColor;
import states.PlayState;

/**
 * Keeps per-song Lua/HScript changes from leaking into menus or later songs.
 * Scripts may alter ClientPrefs or FlxG directly, so restoration happens when
 * PlayState is disposed rather than relying on every mod to clean up itself.
 */
class GameplayStateGuard
{
	final prefs:Map<String, Dynamic> = new Map();
	final stageUI:String;
	final cameraBgColor:FlxColor;
	var restored:Bool = false;

	public function new()
	{
		for (key in Reflect.fields(ClientPrefs.data))
		{
			var value:Dynamic = Reflect.field(ClientPrefs.data, key);
			if (Std.isOfType(value, Array))
				value = (cast value:Array<Dynamic>).copy();
			prefs.set(key, value);
		}
		stageUI = PlayState.stageUI;
		// FlxG.cameras.bgColor proxies the active camera. Lua mods often mutate
		// camGame.bgColor, so the camera Flixel creates during a state switch can
		// otherwise inherit that color before the next PlayState exists.
		cameraBgColor = FlxG.cameras.bgColor;
	}

	public function restore():Void
	{
		if (restored)
			return;
		restored = true;

		for (key in prefs.keys())
			Reflect.setField(ClientPrefs.data, key, prefs.get(key));

		#if !android
		ClientPrefs.data.runOnLightVisual = false;
		#end
		ClientPrefs.applyFramePacing();
		ClientPrefs.saveSettings();

		// Restore this after script teardown and before the next state is created.
		// This keeps a stage-local camera color (AKAGE's red background, for
		// example) from becoming the next stage's implicit camera background.
		FlxG.cameras.bgColor = cameraBgColor;

		if (PlayState.temporaryStageUI == null && stageUI != null)
			PlayState.stageUI = stageUI;
	}
}

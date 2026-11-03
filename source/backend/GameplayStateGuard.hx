package backend;

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

		if (PlayState.temporaryStageUI == null && stageUI != null)
			PlayState.stageUI = stageUI;
	}
}

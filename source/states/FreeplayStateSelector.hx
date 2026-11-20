package states;

import backend.ClientPrefs;
import backend.Mods;
import backend.ScriptableState;
import flixel.FlxState;
import states.plus.FreeplayStatePlus;

class FreeplayStateSelector
{
	public static function create():FlxState
	{
		#if HSCRIPT_ALLOWED
		if (Mods.launchedMod != null && Mods.launchedMod.length > 0 && ScriptableState.hasScript('FreeplayState'))
			return ScriptableState.tryCreate('FreeplayState', new FreeplayState());
		#end

		return ClientPrefs.data.freeplayMenuStyle == 'Plus'
			? ScriptableState.tryCreate('FreeplayStatePlus', new FreeplayStatePlus())
			: ScriptableState.tryCreate('FreeplayState', new FreeplayState());
	}
}


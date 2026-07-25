package states;

import backend.ClientPrefs;
import backend.ScriptableState;
import flixel.FlxState;

class FreeplayStateSelector
{
	public static function create():FlxState
	{
		if (ClientPrefs.data.usePsychFreeplay)
			return ScriptableState.tryCreate('FreeplayState_Psych', new FreeplayState_Psych());

		return ScriptableState.tryCreate('FreeplayState', new FreeplayState());
	}
}

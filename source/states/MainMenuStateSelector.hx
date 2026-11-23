package states;

import backend.ClientPrefs;
import backend.ScriptableState;
import flixel.FlxState;
import states.plus.MainMenuStatePlus;

class MainMenuStateSelector
{
	public static function create():FlxState
	{
		return ClientPrefs.data.mainMenuStyle == 'Plus'
			? ScriptableState.tryCreate('MainMenuStatePlus', new MainMenuStatePlus())
			: ScriptableState.tryCreate('MainMenuState', new MainMenuState());
	}
}

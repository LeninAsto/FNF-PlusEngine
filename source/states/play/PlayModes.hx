package states.play;

class PlayModes
{
	public static inline final DRAIN_FLOOR:Float = 0.2;

	public var perfect:Bool = false;
	public var noDrop:Bool = false;
	public var drain:Bool = false;

	public function new() {}

	public function load():Void
	{
		perfect = ClientPrefs.getGameplaySetting('perfect');
		noDrop = ClientPrefs.getGameplaySetting('nodroppenalty');
		drain = ClientPrefs.getGameplaySetting('opponentdrain');
	}

	public function label(cpu:Bool, practice:Bool, botText:String):String
	{
		if (perfect) return Language.getPhrase('playstate.modes.perfect', Language.getPhrase('perfect_mode', 'Perfect Mode')).toUpperCase();
		if (cpu) return botText;
		if (practice) return Language.getPhrase('playstate.modes.practice', Language.getPhrase('practice_mode', 'Practice Mode')).toUpperCase();
		return '';
	}
}

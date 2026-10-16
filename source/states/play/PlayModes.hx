package states.play;

import objects.Character;

class PlayModes
{
	public static inline final DRAIN_FLOOR:Float = 0.2;

	public var perfect:Bool = false;
	public var opponent:Bool = false;
	public var noDrop:Bool = false;
	public var drain:Bool = false;

	public function new() {}

	public function load():Void
	{
		perfect = ClientPrefs.getGameplaySetting('perfect');
		opponent = ClientPrefs.getGameplaySetting('opponentplay');
		noDrop = ClientPrefs.getGameplaySetting('nodroppenalty');
		drain = ClientPrefs.getGameplaySetting('opponentdrain');
	}

	public inline function player(boyfriend:Character, dad:Character):Character
		return opponent ? dad : boyfriend;

	public inline function rival(boyfriend:Character, dad:Character):Character
		return opponent ? boyfriend : dad;

	public inline function chartHit(gottaHit:Bool):Bool
		return opponent ? !gottaHit : gottaHit;

	public inline function playerStrum(player:Int):Bool
		return opponent ? player == 0 : player == 1;

	public inline function bfHealth(percent:Float):Float
		return opponent ? 1 - percent : percent;

	public inline function dadHealth(percent:Float):Float
		return opponent ? percent : 1 - percent;

	public function label(cpu:Bool, practice:Bool, botText:String):String
	{
		if (perfect) return Language.getPhrase('perfect_mode', 'Perfect Mode').toUpperCase();
		if (opponent) return Language.getPhrase('opponent_mode', 'Opponent Mode').toUpperCase();
		if (cpu) return botText;
		if (practice) return Language.getPhrase('practice_mode', 'Practice Mode').toUpperCase();
		return '';
	}
}

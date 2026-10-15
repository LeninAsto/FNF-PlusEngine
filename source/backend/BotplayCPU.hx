package backend;

import flixel.FlxG;
import objects.Note;

private typedef BotplayCPUProfile =
{
	var missChance:Float;
	var timingSpread:Float;
	var lapseChance:Float;
	var lapseScale:Float;
	var strainMiss:Float;
	var laneBias:Float;
	var holdDropChance:Float;
}

/**
 * Generates persistent, human-like decisions for CPU Botplay notes.
 * Each note is rolled once so its result does not depend on the framerate.
 */
class BotplayCPU
{
	public static final PROFILES:Array<String> = ['Beginner', 'Casual', 'Skilled', 'Expert'];

	static final HIT_KEY:String = '_botplayCPUHit';
	static final OFFSET_KEY:String = '_botplayCPUOffset';

	public final profileName:String;
	final profile:BotplayCPUProfile;
	final laneBias:Array<Float> = [];

	var form:Float = 0;
	var lastHeadTime:Float = -10000;

	public function new(value:Dynamic)
	{
		profileName = normalizeProfile(value);
		profile = getProfile(profileName);
		for (lane in 0...4)
			laneBias.push(gaussian() * profile.laneBias);
	}

	public static function normalizeProfile(value:Dynamic):String
	{
		var name:String = Std.string(value).toLowerCase();
		return switch (name)
		{
			case 'beginner', 'easy', 'rookie': 'Beginner';
			case 'casual', 'normal': 'Casual';
			case 'expert', 'hard': 'Expert';
			default: 'Skilled';
		}
	}

	/** Returns the simulated hit offset in ms, or NaN when this CPU misses. */
	public function hitOffset(note:Note, safeZone:Float):Float
	{
		if (note.extraData.exists(HIT_KEY))
			return note.extraData.get(HIT_KEY) ? note.extraData.get(OFFSET_KEY) : Math.NaN;

		var hit:Bool;
		var offset:Float = 0;
		if (note.isSustainNote)
		{
			// Tail pieces get a very small independent drop chance, allowing re-grabs.
			hit = FlxG.random.float() >= profile.holdDropChance;
		}
		else
		{
			var gap:Float = note.strumTime - lastHeadTime;
			var strain:Float = gap > 4 && gap < 190 ? 1 - ((gap - 4) / 186) : 0;
			lastHeadTime = note.strumTime;

			// Form changes slowly, creating good and bad streaks instead of white noise.
			form = CoolUtil.boundTo(form * 0.88 + FlxG.random.float(-0.22, 0.22), -1, 1);
			var missChance:Float = profile.missChance + (strain * profile.strainMiss) + Math.max(0, form) * profile.missChance;
			hit = FlxG.random.float() >= Math.min(0.65, missChance);

			if (hit)
			{
				var spread:Float = profile.timingSpread * (1 + strain * 0.65 + Math.max(0, form) * 0.35);
				if (FlxG.random.float() < profile.lapseChance)
					spread *= profile.lapseScale;
				var lane:Int = note.noteData % 4;
				offset = gaussian() * spread + laneBias[lane] + form * spread * 0.3;
				offset = CoolUtil.boundTo(offset, -Math.max(1, safeZone) * 0.92, Math.max(1, safeZone) * 0.92);
			}
		}

		note.extraData.set(HIT_KEY, hit);
		note.extraData.set(OFFSET_KEY, offset);
		return hit ? offset : Math.NaN;
	}

	static function getProfile(name:String):BotplayCPUProfile
	{
		return switch (name)
		{
			case 'Beginner': {
				missChance: 0.11, timingSpread: 52, lapseChance: 0.16, lapseScale: 2.1,
				strainMiss: 0.15, laneBias: 14, holdDropChance: 0.012
			};
			case 'Casual': {
				missChance: 0.045, timingSpread: 32, lapseChance: 0.10, lapseScale: 1.8,
				strainMiss: 0.08, laneBias: 9, holdDropChance: 0.006
			};
			case 'Expert': {
				missChance: 0.0025, timingSpread: 9, lapseChance: 0.025, lapseScale: 1.35,
				strainMiss: 0.012, laneBias: 2.5, holdDropChance: 0.0005
			};
			default: {
				missChance: 0.012, timingSpread: 18, lapseChance: 0.055, lapseScale: 1.55,
				strainMiss: 0.035, laneBias: 5, holdDropChance: 0.002
			};
		}
	}

	static function gaussian():Float
	{
		// Box-Muller turns two uniform random values into natural timing variation.
		var a:Float = Math.max(0.000001, FlxG.random.float());
		var b:Float = FlxG.random.float();
		return Math.sqrt(-2 * Math.log(a)) * Math.cos(2 * Math.PI * b);
	}
}

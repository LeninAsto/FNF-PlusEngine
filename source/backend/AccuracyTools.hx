package backend;

class AccuracyTools
{
	public static inline final BONUS_MAX:Float = 1;

	public static function withBonus(base:Float, played:Int, total:Int, bonusLimit:Float):Float
	{
		if (played <= 0)
			return 0;

		var accuracy:Float = Math.max(0, base);
		if (!ClientPrefs.data.overAccuracy)
			return Math.min(1, accuracy);

		var bonus:Float = Math.min(progress(played, total), Math.max(0, Math.min(BONUS_MAX, bonusLimit)));
		return Math.min(2, accuracy + bonus);
	}

	public static function progress(played:Int, total:Int):Float
	{
		if (played <= 0 || total <= 0)
			return 0;

		return Math.max(0, Math.min(BONUS_MAX, played / total));
	}

	public static function format(value:Float, ?allowOver:Null<Bool>):String
	{
		if (Math.isNaN(value))
			value = 0;

		if (allowOver == null)
			allowOver = ClientPrefs.data.overAccuracy;
		if (!allowOver)
			value = Math.min(1, value);

		var percent:Float = CoolUtil.floorDecimal(value * 100, 2);
		if (percent <= 100)
			return fixed(percent) + '%';

		return '100% + ' + fixed(percent - 100) + '%';
	}

	static function fixed(value:Float):String
	{
		var split:Array<String> = Std.string(Math.abs(CoolUtil.floorDecimal(value, 2))).split('.');
		if (split.length < 2)
			split.push('');
		while (split[1].length < 2)
			split[1] += '0';

		var text:String = split.join('.');
		return value < 0 ? '-' + text : text;
	}
}

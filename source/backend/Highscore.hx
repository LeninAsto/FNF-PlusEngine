package backend;

class Highscore
{
	public static var weekScores:Map<String, Int> = new Map();
	public static var songScores:Map<String, Int> = new Map<String, Int>();
	public static var songRating:Map<String, Float> = new Map<String, Float>();
	public static var songAccuracySystem:Map<String, String> = new Map<String, String>();
	
	// Opponent Mode - Scores separados
	public static var songScoresOpponent:Map<String, Int> = new Map<String, Int>();
	public static var songRatingOpponent:Map<String, Float> = new Map<String, Float>();
	public static var songAccuracySystemOpponent:Map<String, String> = new Map<String, String>();

	public static function resetSong(song:String, diff:Int = 0):Void
	{
		var daSong:String = formatSong(song, diff);
		setScore(daSong, 0);
		setRating(daSong, 0);
	}

	public static function resetWeek(week:String, diff:Int = 0):Void
	{
		var daWeek:String = formatSong(week, diff);
		setWeekScore(daWeek, 0);
	}

	public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0, ?rating:Float = -1, ?isOpponentMode:Bool = false, ?accuracySystem:String = null):Void
	{
		if(song == null) return;
		var daSong:String = formatSong(song, diff);

		// Seleccionar el mapa correcto según el modo
		var scoreMap:Map<String, Int> = isOpponentMode ? songScoresOpponent : songScores;
		var ratingMap:Map<String, Float> = isOpponentMode ? songRatingOpponent : songRating;
		var systemMap:Map<String, String> = isOpponentMode ? songAccuracySystemOpponent : songAccuracySystem;

		if (scoreMap.exists(daSong))
		{
			if (scoreMap.get(daSong) < score)
			{
				setScore(daSong, score, isOpponentMode);
				// Wife3 permite ratings negativos y >1.0, solo guardamos si fue especificado (diferente de -1)
				if(rating != -1) setRating(daSong, rating, isOpponentMode);
				if(accuracySystem != null) setAccuracySystem(daSong, accuracySystem, isOpponentMode);
			}
			// Si el score es igual pero el rating es mejor, actualiza solo el rating
			else if (scoreMap.get(daSong) == score && rating != -1)
			{
				var currentRating:Float = getRating(song, diff, isOpponentMode);
				if(rating > currentRating) {
					setRating(daSong, rating, isOpponentMode);
					if(accuracySystem != null) setAccuracySystem(daSong, accuracySystem, isOpponentMode);
				}
			}
		}
		else
		{
			setScore(daSong, score, isOpponentMode);
			// Wife3 permite ratings negativos y >1.0, solo guardamos si fue especificado
			if(rating != -1) setRating(daSong, rating, isOpponentMode);
			if(accuracySystem != null) setAccuracySystem(daSong, accuracySystem, isOpponentMode);
		}
	}

	public static function saveWeekScore(week:String, score:Int = 0, ?diff:Int = 0):Void
	{
		var daWeek:String = formatSong(week, diff);

		if (weekScores.exists(daWeek))
		{
			if (weekScores.get(daWeek) < score)
				setWeekScore(daWeek, score);
		}
		else setWeekScore(daWeek, score);
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	 */
	static function setScore(song:String, score:Int, isOpponentMode:Bool = false):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		if(isOpponentMode)
		{
			songScoresOpponent.set(song, score);
			FlxG.save.data.songScoresOpponent = songScoresOpponent;
		}
		else
		{
			songScores.set(song, score);
			FlxG.save.data.songScores = songScores;
		}
		FlxG.save.flush();
	}
	static function setWeekScore(week:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		weekScores.set(week, score);
		FlxG.save.data.weekScores = weekScores;
		FlxG.save.flush();
	}

	static function setRating(song:String, rating:Float, isOpponentMode:Bool = false):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		if(isOpponentMode)
		{
			songRatingOpponent.set(song, rating);
			FlxG.save.data.songRatingOpponent = songRatingOpponent;
		}
		else
		{
			songRating.set(song, rating);
			FlxG.save.data.songRating = songRating;
		}
		FlxG.save.flush();
	}

	static function setAccuracySystem(song:String, system:String, isOpponentMode:Bool = false):Void
	{
		if(isOpponentMode)
		{
			songAccuracySystemOpponent.set(song, system);
			FlxG.save.data.songAccuracySystemOpponent = songAccuracySystemOpponent;
		}
		else
		{
			songAccuracySystem.set(song, system);
			FlxG.save.data.songAccuracySystem = songAccuracySystem;
		}
		FlxG.save.flush();
	}

	public static function getAccuracySystem(song:String, diff:Int, isOpponentMode:Bool = false):String
	{
		var daSong:String = formatSong(song, diff);
		var systemMap:Map<String, String> = isOpponentMode ? songAccuracySystemOpponent : songAccuracySystem;
		
		if (!systemMap.exists(daSong))
			return 'Unknown';

		return systemMap.get(daSong);
	}

	public static function formatSong(song:String, diff:Int):String
	{
		return Paths.formatToSongPath(song) + Difficulty.getFilePath(diff);
	}

	public static function getScore(song:String, diff:Int, isOpponentMode:Bool = false):Int
	{
		var daSong:String = formatSong(song, diff);
		var scoreMap:Map<String, Int> = isOpponentMode ? songScoresOpponent : songScores;
		
		if (!scoreMap.exists(daSong))
			setScore(daSong, 0, isOpponentMode);

		return scoreMap.get(daSong);
	}

	public static function getRating(song:String, diff:Int, isOpponentMode:Bool = false):Float
	{
		var daSong:String = formatSong(song, diff);
		var ratingMap:Map<String, Float> = isOpponentMode ? songRatingOpponent : songRating;
		
		if (!ratingMap.exists(daSong))
			setRating(daSong, 0, isOpponentMode);

		return ratingMap.get(daSong);
	}

	public static function getWeekScore(week:String, diff:Int):Int
	{
		var daWeek:String = formatSong(week, diff);
		if (!weekScores.exists(daWeek))
			setWeekScore(daWeek, 0);

		return weekScores.get(daWeek);
	}

	public static function load():Void
	{
		if (FlxG.save.data.weekScores != null)
			weekScores = FlxG.save.data.weekScores;

		if (FlxG.save.data.songScores != null)
			songScores = FlxG.save.data.songScores;

		if (FlxG.save.data.songRating != null)
			songRating = FlxG.save.data.songRating;

		// Cargar sistemas de accuracy
		if (FlxG.save.data.songAccuracySystem != null)
			songAccuracySystem = FlxG.save.data.songAccuracySystem;

		// Cargar scores de Opponent Mode
		if (FlxG.save.data.songScoresOpponent != null)
			songScoresOpponent = FlxG.save.data.songScoresOpponent;

		if (FlxG.save.data.songRatingOpponent != null)
			songRatingOpponent = FlxG.save.data.songRatingOpponent;

		if (FlxG.save.data.songAccuracySystemOpponent != null)
			songAccuracySystemOpponent = FlxG.save.data.songAccuracySystemOpponent;
	}
}
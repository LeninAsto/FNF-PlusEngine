package backend;

#if FEATURE_POLYMOD_MODS
import funkin.play.scoring.Scoring;
import funkin.save.Save;
import funkin.save.Save.SaveScoreData;
#end

class Highscore
{
	public static var weekScores:Map<String, Int> = new Map();
	public static var songScores:Map<String, Int> = new Map<String, Int>();
	public static var songRating:Map<String, Float> = new Map<String, Float>();
	public static var songAccuracySystem:Map<String, String> = new Map<String, String>();

	// Opponent Mode - Separate scores
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

	public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0, ?rating:Float = -1, ?isOpponentMode:Bool = false,
			?accuracySystem:String = null):Void
	{
		if (song == null)
			return;
		var daSong:String = formatSong(song, diff);

		// Select the correct map based on the mode
		var scoreMap:Map<String, Int> = isOpponentMode ? songScoresOpponent : songScores;
		var ratingMap:Map<String, Float> = isOpponentMode ? songRatingOpponent : songRating;
		var systemMap:Map<String, String> = isOpponentMode ? songAccuracySystemOpponent : songAccuracySystem;

		if (scoreMap.exists(daSong))
		{
			if (scoreMap.get(daSong) < score)
			{
				setScore(daSong, score, isOpponentMode);
				// Wife3 allows negative ratings and ratings greater than 1.0; we only save them if they were specified (other than -1).
				if (rating != -1)
					setRating(daSong, rating, isOpponentMode);
				if (accuracySystem != null)
					setAccuracySystem(daSong, accuracySystem, isOpponentMode);
			}
			// If the score is the same but the rating is better, update only the rating
			else if (scoreMap.get(daSong) == score && rating != -1)
			{
				var currentRating:Float = getRating(song, diff, isOpponentMode);
				if (rating > currentRating)
				{
					setRating(daSong, rating, isOpponentMode);
					if (accuracySystem != null)
						setAccuracySystem(daSong, accuracySystem, isOpponentMode);
				}
			}
		}
		else
		{
			setScore(daSong, score, isOpponentMode);
			// Wife3 allows negative ratings and ratings greater than 1.0; we only save them if they were specified
			if (rating != -1)
				setRating(daSong, rating, isOpponentMode);
			if (accuracySystem != null)
				setAccuracySystem(daSong, accuracySystem, isOpponentMode);
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
		else
			setWeekScore(daWeek, score);
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	 */
	static function setScore(song:String, score:Int, isOpponentMode:Bool = false):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		if (isOpponentMode)
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
		if (isOpponentMode)
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
		if (isOpponentMode)
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

	public static function getVSliceScore(songId:String, difficulty:String, variation:String = 'default'):Int
	{
		#if FEATURE_POLYMOD_MODS
		var scoreData:Null<SaveScoreData> = getVSliceScoreData(songId, difficulty, variation);
		return scoreData != null ? scoreData.score : 0;
		#else
		return 0;
		#end
	}

	public static function getVSliceRating(songId:String, difficulty:String, variation:String = 'default'):Float
	{
		#if FEATURE_POLYMOD_MODS
		var scoreData:Null<SaveScoreData> = getVSliceScoreData(songId, difficulty, variation);
		if (scoreData == null || scoreData.tallies == null || scoreData.tallies.totalNotes <= 0)
			return 0;
		return Scoring.tallyCompletion(scoreData.tallies);
		#else
		return 0;
		#end
	}

	public static function getVSliceAccuracySystem(songId:String, difficulty:String, variation:String = 'default'):String
	{
		#if FEATURE_POLYMOD_MODS
		return getVSliceScoreData(songId, difficulty, variation) != null ? 'VSlice' : 'Unknown';
		#else
		return 'Unknown';
		#end
	}

	public static function getVSliceWeekScore(levelId:String, difficulty:String = 'normal'):Int
	{
		#if FEATURE_POLYMOD_MODS
		if (levelId == null || levelId.length == 0)
			return 0;
		if (difficulty == null || difficulty.length == 0)
			difficulty = 'normal';
		try
		{
			if (Save.instance == null)
				Save.load();
			var scoreData:Null<SaveScoreData> = Save.instance.getLevelScore(levelId, difficulty);
			return scoreData != null ? scoreData.score : 0;
		}
		catch (_:Dynamic)
		{
		}
		#end
		return 0;
	}

	#if FEATURE_POLYMOD_MODS
	static function getVSliceScoreData(songId:String, difficulty:String, variation:String = 'default'):Null<SaveScoreData>
	{
		if (songId == null || songId.length == 0)
			return null;
		if (difficulty == null || difficulty.length == 0)
			difficulty = 'normal';
		try
		{
			if (Save.instance == null)
				Save.load();
			var scoreData:Null<SaveScoreData> = Save.instance.getSongScore(songId, difficulty, variation);
			if (scoreData != null)
				return scoreData;

			var suffixedDifficulty:String = getVSliceSuffixedDifficulty(difficulty, variation);
			if (suffixedDifficulty != difficulty)
			{
				scoreData = Save.instance.getSongScore(songId, suffixedDifficulty);
				if (scoreData != null)
					return scoreData;
			}

			var normalizedSongId:String = Paths.formatToSongPath(songId);
			if (normalizedSongId != songId)
			{
				scoreData = Save.instance.getSongScore(normalizedSongId, difficulty, variation);
				if (scoreData != null)
					return scoreData;
				if (suffixedDifficulty != difficulty)
				{
					scoreData = Save.instance.getSongScore(normalizedSongId, suffixedDifficulty);
					if (scoreData != null)
						return scoreData;
				}
			}
		}
		catch (_:Dynamic)
		{
		}
		return null;
	}
	#end

	static function getVSliceSuffixedDifficulty(difficulty:String, variation:String):String
	{
		if (variation != null && variation.length > 0 && variation != 'default' && variation != 'erect' && difficulty.indexOf('-$variation') == -1)
			return '$difficulty-$variation';
		return difficulty;
	}

	public static function formatSong(song:String, diff:Int):String
	{
		return Paths.formatToSongPath(song) + Difficulty.getFilePath(diff);
	}

	public static function getScore(song:String, diff:Int, isOpponentMode:Bool = false):Int
	{
		var daSong:String = formatSong(song, diff);
		var scoreMap:Map<String, Int> = isOpponentMode ? songScoresOpponent : songScores;
		return scoreMap.exists(daSong) ? scoreMap.get(daSong) : 0;
	}

	public static function getRating(song:String, diff:Int, isOpponentMode:Bool = false):Float
	{
		var daSong:String = formatSong(song, diff);
		var ratingMap:Map<String, Float> = isOpponentMode ? songRatingOpponent : songRating;
		return ratingMap.exists(daSong) ? ratingMap.get(daSong) : 0;
	}

	public static function getWeekScore(week:String, diff:Int):Int
	{
		var daWeek:String = formatSong(week, diff);
		return weekScores.exists(daWeek) ? weekScores.get(daWeek) : 0;
	}

	public static function load():Void
	{
		if (FlxG.save.data.weekScores != null)
			weekScores = FlxG.save.data.weekScores;

		if (FlxG.save.data.songScores != null)
			songScores = FlxG.save.data.songScores;

		if (FlxG.save.data.songRating != null)
			songRating = FlxG.save.data.songRating;

		// Load accuracy systems
		if (FlxG.save.data.songAccuracySystem != null)
			songAccuracySystem = FlxG.save.data.songAccuracySystem;

		// Load Opponent Mode scores
		if (FlxG.save.data.songScoresOpponent != null)
			songScoresOpponent = FlxG.save.data.songScoresOpponent;

		if (FlxG.save.data.songRatingOpponent != null)
			songRatingOpponent = FlxG.save.data.songRatingOpponent;

		if (FlxG.save.data.songAccuracySystemOpponent != null)
			songAccuracySystemOpponent = FlxG.save.data.songAccuracySystemOpponent;
	}
}


package backend;

class Difficulty
{
	public static final defaultList:Array<String> = ['Easy', 'Normal', 'Hard'];
	private static final defaultDifficulty:String = 'Normal'; // The chart that has no postfix and starting difficulty on Freeplay/Story Mode

	public static var list:Array<String> = [];

	/** Freeplay may use the week declaration or discover the song's chart files. */
	public static function loadForSong(song:String):Void
	{
		loadFromWeek();
		if (ClientPrefs.data.difficultySource != 'Charts') return;
		var name = Paths.formatToSongPath(song);
		var relative = 'data/$name/';
		var directories:Array<String> = [Paths.getSharedPath(relative)];
		#if MODS_ALLOWED
		for (mod in Mods.getGlobalMods()) directories.push(Paths.mods(mod + '/' + relative));
		directories.push(Paths.mods(relative));
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			directories.push(Paths.mods(Mods.currentModDirectory + '/' + relative));
		#end
		var files:Array<String> = [];
		for (dir in directories)
			for (file in Paths.readDirectory(dir)) if (!files.contains(file)) files.push(file);
		// Packaged assets may not expose directories on disk.
		for (asset in openfl.utils.Assets.list())
			for (dir in directories)
				if (asset.startsWith(dir))
				{
					var file = asset.substr(dir.length);
					if (file.indexOf('/') < 0 && !files.contains(file)) files.push(file);
				}
		var found:Array<String> = [];
		for (file in files)
		{
			var lower = file.toLowerCase();
			if (!lower.endsWith('.json')) continue;
			var stem = lower.substr(0, lower.length - 5);
			var diff = stem == name ? 'normal' : (stem.startsWith(name + '-') ? stem.substr(name.length + 1) : '');
			if (diff.length == 0) continue;
			var display = [for (part in diff.split('-')) part.length > 0 ? part.charAt(0).toUpperCase() + part.substr(1) : ''].join(' ');
			if (!found.contains(display)) found.push(display);
		}
		var order = ['Beginner', 'Easy', 'Normal', 'Medium', 'Hard', 'Challenge', 'Edit'];
		found.sort(function(a, b) {
			var ai = order.indexOf(a), bi = order.indexOf(b);
			if (ai < 0) ai = order.length;
			if (bi < 0) bi = order.length;
			return ai == bi ? Reflect.compare(a.toLowerCase(), b.toLowerCase()) : ai - bi;
		});
		if (found.length > 0) list = found;
	}

	inline public static function getFilePath(num:Null<Int> = null)
	{
		if (num == null)
			num = PlayState.storyDifficulty;

		var filePostfix:String = list[num];
		if (filePostfix != null && Paths.formatToSongPath(filePostfix) != Paths.formatToSongPath(defaultDifficulty))
			filePostfix = '-' + filePostfix;
		else
			filePostfix = '';
		return Paths.formatToSongPath(filePostfix);
	}

	inline public static function loadFromWeek(week:WeekData = null)
	{
		if (week == null)
			week = WeekData.getCurrentWeek();

		var diffStr:String = week.difficulties;
		if (diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.trim().split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if (diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if (diffs[i].length < 1)
						diffs.remove(diffs[i]);
				}
				--i;
			}

			if (diffs.length > 0 && diffs[0].length > 0)
				list = diffs;
		}
		else
			resetList();
	}

	inline public static function resetList()
	{
		list = defaultList.copy();
	}

	inline public static function copyFrom(diffs:Array<String>)
	{
		list = diffs.copy();
	}

	inline public static function getString(?num:Null<Int> = null, ?canTranslate:Bool = true):String
	{
		var diffName:String = list[num == null ? PlayState.storyDifficulty : num];
		if (diffName == null)
			diffName = defaultDifficulty;
		return canTranslate ? Language.getPhrase('difficulty_$diffName', diffName) : diffName;
	}

	inline public static function getDefault():String
	{
		return defaultDifficulty;
	}
}


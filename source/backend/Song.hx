package backend;

import haxe.Json;
import lime.utils.Assets;
import backend.AssetLoader;
import openfl.utils.AssetType;
import objects.Note;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var offset:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	var format:String;

	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;

	@:optional var disableNoteRGB:Bool;

	@:optional var arrowSkin:String;
	@:optional var splashSkin:String;
	@:optional var isAnimated:Bool;
	@:optional var useModcharts:Bool;
	@:optional var extendedEventValues:Bool;
	@:optional var extraStrumLines:Array<ExtraStrumLineData>;
}

typedef ExtraStrumLineData =
{
	var id:String;
	var notes:Array<Dynamic>;
	@:optional var character:String;
	@:optional var visible:Bool;
	@:optional var x:Float;
	@:optional var y:Float;
	@:optional var scale:Float;
	@:optional var spacing:Float;
}

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Float;
	var mustHitSection:Bool;
	@:optional var altAnim:Bool;
	@:optional var gfSection:Bool;
	@:optional var bpm:Float;
	@:optional var changeBPM:Bool;
}

// ── psych_v2 typedefs ────────────────────────────────────────────────────────

/** Flat note entry used in the psych_v2 format. */
typedef SongNoteV2 =
{
	var t:Float; // strumTime (ms)
	var d:Int; // 0-3 = player, 4-7 = opponent (absolute, no mustHitSection)
	var l:Float; // sustainLength in ms (0 = tap note)
	@:optional var type:String; // note type string; omit for default
}

/** Flat event entry used in the psych_v2 format. */
typedef SongEventV2 =
{
	var t:Float; // time in ms
	var name:String; // event name
	var v:Dynamic; // arbitrary value payload
}

/** BPM change entry used in the psych_v2 format. */
typedef BpmChangeV2 =
{
	var time:Float; // time in ms at which the new BPM takes effect
	var bpm:Float;
}

/** Character names used in the psych_v2 format. */
typedef SongCharactersV2 =
{
	var player:String;
	var opponent:String;
	var girlfriend:String;
}

class Song
{
	public static var chartCache:Map<String, String> = new Map();
	static var chartCacheOrder:Array<String> = [];
	static inline final MAX_CHART_CACHE_ENTRIES:Int = 4;
	static inline final MAX_CACHED_CHART_BYTES:Int = 2 * 1024 * 1024;
	static inline final MAX_AUTO_CONVERT_SAVE_BYTES:Int = 2 * 1024 * 1024;

	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String;
	public var splashSkin:String;
	public var gameOverChar:String;
	public var gameOverSound:String;
	public var gameOverLoop:String;
	public var gameOverEnd:String;
	public var disableNoteRGB:Bool = false;
	public var speed:Float = 1;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';
	public var format:String = 'psych_v1';

	public static function convert(songJson:Dynamic) // Convert old charts to psych_v1 format
	{
		if (songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			if (Reflect.hasField(songJson, 'player3'))
				Reflect.deleteField(songJson, 'player3');
		}

		var sectionsData:Array<SwagSection> = songJson.notes;
		if (sectionsData == null)
			return;
		var extractEvents:Bool = songJson.events == null;
		if (extractEvents)
			songJson.events = [];

		for (section in sectionsData)
		{
			var beats:Null<Float> = cast section.sectionBeats;
			if (beats == null || Math.isNaN(beats))
			{
				section.sectionBeats = 4;
				if (Reflect.hasField(section, 'lengthInSteps'))
					Reflect.deleteField(section, 'lengthInSteps');
			}

			var notes:Array<Dynamic> = section.sectionNotes;
			var i:Int = 0;
			while (notes != null && i < notes.length)
			{
				var note:Array<Dynamic> = notes[i];
				if (extractEvents && note[1] < 0)
				{
					songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
					notes.splice(i, 1);
					continue;
				}
				var gottaHitNote:Bool = (note[1] < 4) ? section.mustHitSection : !section.mustHitSection;
				note[1] = (note[1] % 4) + (gottaHitNote ? 0 : 4);

				if (!Std.isOfType(note[3], String))
					note[3] = Note.defaultNoteTypes[note[3]]; // compatibility with Week 7 and 0.1-0.3 psych charts
				i++;
			}
		}
	}

	public static var chartPath:String;
	public static var loadedSongName:String;
	public static var lastDetectedSourceFormat:String = '';

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		if (folder == null)
			folder = jsonInput;
		SongLoadMetrics.begin();
		var chartStarted:Float = haxe.Timer.stamp();
		CompiledChartCache.resetHit();
		PlayState.SONG = getChart(jsonInput, folder);
		SongLoadMetrics.recordChart((haxe.Timer.stamp() - chartStarted) * 1000, CompiledChartCache.lastHit);
		loadedSongName = folder;
		chartPath = _lastPath;
		if (PlayState.SONG == null)
		{
			trace('Failed to load chart "$jsonInput" from folder "$folder"');
			return null;
		}
		#if windows
		// prevent any saving errors by fixing the path on Windows (being the only OS to ever use backslashes instead of forward slashes for paths)
		chartPath = chartPath.replace('/', '\\');
		#end
		StageData.loadDirectory(PlayState.SONG);

		// Auto-save psych_v2 -> psych_v1
		#if MODS_ALLOWED
		if (PlayState.SONG != null && _lastPath != null && sys.FileSystem.exists(_lastPath))
		{
			var needsSave:Bool = false;
			var conversionMsg:String = '';

			if (lastDetectedSourceFormat != null && lastDetectedSourceFormat.startsWith('psych_v2'))
			{
				conversionMsg = 'psych_v2 -> psych_v1';
				needsSave = true;
			}
			else if (lastDetectedSourceFormat == 'non_formatted')
			{
				conversionMsg = 'non_formatted -> psych_v1';
				needsSave = true;
			}

			var canAutoSave:Bool = sys.FileSystem.stat(_lastPath).size <= MAX_AUTO_CONVERT_SAVE_BYTES;
			if (needsSave && canAutoSave)
			{
				trace('Saving converted chart: $conversionMsg');
				PlayState.SONG.format = 'psych_v1';
				saveChart(PlayState.SONG, _lastPath);
			}
			else if (needsSave)
				trace('Skipping converted chart rewrite because the source is too large: $_lastPath');
		}
		#end

		return PlayState.SONG;
	}

	static var _lastPath:String;

	public static function expectedChartPath(jsonInput:String, ?folder:String):String
	{
		if (folder == null)
			folder = jsonInput;
		return Paths.json('${Paths.formatToSongPath(folder)}/${Paths.formatToSongPath(jsonInput)}');
	}

	/** Resolves a Psych chart path without loading or parsing the chart. */
	public static function resolveChartPath(jsonInput:String, ?folder:String):Null<String>
	{
		if (folder == null)
			folder = jsonInput;

		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		var directPath:String = Paths.json('$formattedFolder/$formattedSong');
		if (AssetLoader.exists(directPath, TEXT))
			return directPath;

		var hasDifficultySuffix:Bool = false;
		for (diff in Difficulty.list)
		{
			var suffix:String = '-' + Paths.formatToSongPath(diff);
			if (formattedSong.endsWith(suffix))
			{
				hasDifficultySuffix = true;
				break;
			}
		}

		var normal:String = Paths.formatToSongPath(Difficulty.getDefault());
		if (!hasDifficultySuffix)
		{
			var normalPath:String = Paths.json('$formattedFolder/$formattedSong-$normal');
			if (AssetLoader.exists(normalPath, TEXT))
				return normalPath;
		}
		else if (formattedSong.endsWith('-$normal'))
		{
			var baseSong:String = formattedSong.substr(0, formattedSong.length - normal.length - 1);
			var basePath:String = Paths.json('$formattedFolder/$baseSong');
			if (AssetLoader.exists(basePath, TEXT))
				return basePath;
		}

		return null;
	}

	public static function getChart(jsonInput:String, ?folder:String):SwagSong
	{
		if (folder == null)
			folder = jsonInput;

		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		_lastPath = resolveChartPath(jsonInput, folder);
		if (_lastPath == null)
		{
			_lastPath = expectedChartPath(jsonInput, folder);
			return null;
		}

		#if MODS_ALLOWED
		// Compatibility with Psych 0.7.3: If the chart doesn't exist,
		// try loading it with the suffix “-normal” for older mods
		var pathExists:Bool = AssetLoader.exists(_lastPath, TEXT);
		if (!pathExists)
		{
			// Check if jsonInput already has a difficulty suffix
			var hasDifficultySuffix:Bool = false;
			for (diff in Difficulty.list)
			{
				var diffSuffix:String = '-' + Paths.formatToSongPath(diff);
				if (formattedSong.endsWith(diffSuffix))
				{
					hasDifficultySuffix = true;
					break;
				}
			}

			// If there is no suffix, try “-normal” (compatibility 0.7.3)
			var normalDiff:String = Paths.formatToSongPath(Difficulty.getDefault()); // "normal"
			if (!hasDifficultySuffix)
			{
				var altPath:String = Paths.json('$formattedFolder/$formattedSong-$normalDiff');
				if (AssetLoader.exists(altPath, TEXT))
				{
					_lastPath = altPath;
					pathExists = true;
					trace('Psych 0.7.3 Compatibility: Using "$formattedSong-$normalDiff" chart');
				}
			}
			else if (formattedSong.endsWith('-$normalDiff'))
			{
				var baseSong:String = formattedSong.substr(0, formattedSong.length - normalDiff.length - 1);
				var altPath:String = Paths.json('$formattedFolder/$baseSong');
				if (AssetLoader.exists(altPath, TEXT))
				{
					_lastPath = altPath;
					pathExists = true;
					trace('Normal chart compatibility: Using "$baseSong" chart');
				}
			}
		}
		#end
		var compiled:SwagSong = CompiledChartCache.load(_lastPath);
		if (compiled != null)
		{
			lastDetectedSourceFormat = 'compiled_cache';
			return compiled;
		}
		var rawData:String = getCachedChart(_lastPath);
		if (rawData == null)
		{
			rawData = AssetLoader.loadText(_lastPath);
			if (rawData != null)
				cacheChart(_lastPath, rawData);
		}

		var parsed:SwagSong = rawData != null ? parseJSON(rawData, jsonInput) : null;
		if (parsed != null)
			CompiledChartCache.queueSave(_lastPath, parsed);
		return parsed;
	}

	public static function getEventsChart(folder:String):SwagSong
	{
		var sidecarPath:String = getChartSidecarPath('events');
		if (sidecarPath != null && AssetLoader.exists(sidecarPath, TEXT))
		{
			var rawData:String = getCachedChart(sidecarPath);
			if (rawData == null)
			{
				rawData = AssetLoader.loadText(sidecarPath);
				if (rawData != null)
					cacheChart(sidecarPath, rawData);
			}

			if (rawData != null)
				return parseJSON(rawData, 'events');
		}

		if (chartBelongsToExternalMod())
			return null;

		return getChart('events', folder);
	}

	static function getChartSidecarPath(name:String):String
	{
		if (chartPath == null || chartPath.length < 1)
			return null;

		var normalized:String = chartPath.replace('\\', '/');
		var slash:Int = normalized.lastIndexOf('/');
		if (slash < 0)
			return null;

		return normalized.substr(0, slash + 1) + name + '.json';
	}

	static function chartBelongsToExternalMod():Bool
	{
		#if MODS_ALLOWED
		if (chartPath == null || chartPath.length < 1)
			return false;

		var relative:String = Paths.getModRelativePath(chartPath);
		if (relative == null || relative.length < 1)
			return false;

		var modFolder:String = relative.split('/')[0];
		return modFolder != null && modFolder.length > 0 && !Mods.isBaseGameMod(modFolder);
		#else
		return false;
		#end
	}

	public static function clearChartCache():Void
	{
		chartCache.clear();
		chartCacheOrder.resize(0);
	}

	/** Invalidates every cached representation of a chart after it is saved. */
	public static function invalidateChartCache(path:String):Void
	{
		if (path == null || path.length == 0)
			return;

		var normalized:String = path.replace('\\', '/').toLowerCase();
		var matches:Array<String> = [];
		for (key in chartCache.keys())
			if (key != null && key.replace('\\', '/').toLowerCase() == normalized)
				matches.push(key);
		for (key in matches)
		{
			chartCache.remove(key);
			while (chartCacheOrder.remove(key)) {}
		}
		CompiledChartCache.invalidate(path);
	}

	static function getCachedChart(path:String):String
	{
		var data:String = chartCache.get(path);
		if (data != null)
		{
			chartCacheOrder.remove(path);
			chartCacheOrder.push(path);
		}
		return data;
	}

	static function cacheChart(path:String, data:String):Void
	{
		if (data.length > MAX_CACHED_CHART_BYTES)
			return;
		chartCache.set(path, data);
		chartCacheOrder.remove(path);
		chartCacheOrder.push(path);
		while (chartCacheOrder.length > MAX_CHART_CACHE_ENTRIES)
			chartCache.remove(chartCacheOrder.shift());
	}

	public static function parseJSON(rawData:String, ?nameForError:String = null, ?convertTo:String = 'psych_v1'):SwagSong
	{
		lastDetectedSourceFormat = '';
		if (rawData == null || rawData.length == 0)
			return null;

		var songJson:SwagSong = null;
		try
		{
			songJson = cast Json.parse(rawData);
		}
		catch (e:Dynamic)
		{
			trace('Failed to parse chart ${nameForError != null ? nameForError : ""}: $e');
			return null;
		}

		if (songJson == null)
			return null;

		if (Reflect.hasField(songJson, 'song'))
		{
			var subSong:SwagSong = Reflect.field(songJson, 'song');
			if (subSong != null && Type.typeof(subSong) == TObject)
				songJson = subSong;
		}

		if (songJson == null)
			return null;

		// Detect if the chart is not formatted (single line with no line breaks)
		var fmt:String = songJson.format;
		if (fmt == null || fmt.length == 0)
		{
			// Check if the raw data has no line breaks (single line = unformatted)
			var firstBreak:Int = rawData.indexOf('\n');
			var compact:Bool = firstBreak < 0 || rawData.indexOf('\n', firstBreak + 1) < 0;
			if (compact) // Allow 1-2 lines for very compact JSON
			{
				fmt = 'non_formatted';
				trace('Detected non-formatted chart (single line): $nameForError');
			}
			else
			{
				fmt = 'unknown';
			}
		}
		lastDetectedSourceFormat = fmt;

		// Auto-detect and convert psych_v2 -> psych_v1
		if (fmt.startsWith('psych_v2'))
		{
			trace('Converting chart $nameForError from psych_v2 -> psych_v1 format...');
			songJson = downgradeFromV2(songJson);
			songJson.format = 'psych_v1';
			return songJson;
		}

		if (fmt == 'non_formatted')
		{
			trace('Converting chart $nameForError from non_formatted -> psych_v1 format...');
			songJson.format = 'psych_v1';
			convert(songJson);
			return songJson;
		}

		if (convertTo != null && convertTo.length > 0)
		{
			switch (convertTo)
			{
				case 'psych_v1':
					if (!fmt.startsWith('psych_v1')) // Convert to Psych 1.0 format
					{
						trace('converting chart $nameForError with format $fmt to psych_v1 format...');
						songJson.format = 'psych_v1_convert';
						convert(songJson);
					}
			}
		}
		return songJson;
	}

	/**
	 * Saves a SwagSong to disk as psych_v1 JSON
	 */
	private static function saveChart(song:SwagSong, filePath:String):Void
	{
		#if MODS_ALLOWED
		try
		{
			var jsonStr:String = haxe.Json.stringify(song);
			// Pretty-print the JSON
			var obj:Dynamic = haxe.Json.parse(jsonStr);
			var prettyJson:String = formatJson(obj, 0);

			sys.io.File.saveContent(filePath, prettyJson);
			invalidateChartCache(filePath);
			trace('Chart saved: $filePath');
		}
		catch (e:Dynamic)
		{
			trace('Error saving chart: $e');
		}
		#end
	}

	/**
	 * Format JSON object as pretty-printed string
	 */
	private static function formatJson(obj:Dynamic, indent:Int = 0):String
	{
		var indentStr:String = '';
		for (i in 0...indent)
			indentStr += '\t';
		var nextIndentStr:String = '';
		for (i in 0...indent + 1)
			nextIndentStr += '\t';

		if (obj == null)
			return 'null';

		var type = Type.typeof(obj);

		switch (type)
		{
			case TInt | TFloat | TBool:
				return Std.string(obj);

			case TClass(String):
				return haxe.Json.stringify(Std.string(obj));

			case TObject:
				var fields:Array<String> = Reflect.fields(obj);
				if (fields.length == 0)
					return '{}';

				var result:String = '{\n';
				for (i in 0...fields.length)
				{
					var field:String = fields[i];
					var value:Dynamic = Reflect.field(obj, field);
					result += nextIndentStr + '"' + field + '": ' + formatJson(value, indent + 1);
					if (i < fields.length - 1)
						result += ',';
					result += '\n';
				}
				result += indentStr + '}';
				return result;

			default:
		}

		if (Std.isOfType(obj, Array))
		{
			var arr:Array<Dynamic> = cast obj;
			if (arr.length == 0)
				return '[]';

			var result:String = '[\n';
			for (i in 0...arr.length)
			{
				result += nextIndentStr + formatJson(arr[i], indent + 1);
				if (i < arr.length - 1)
					result += ',';
				result += '\n';
			}
			result += indentStr + ']';
			return result;
		}

		if (type == TObject)
		{
			var fields:Array<String> = Reflect.fields(obj);
			if (fields.length == 0)
				return '{}';

			var result:String = '{\n';
			for (i in 0...fields.length)
			{
				var field:String = fields[i];
				var value:Dynamic = Reflect.field(obj, field);
				result += nextIndentStr + '"' + field + '": ' + formatJson(value, indent + 1);
				if (i < fields.length - 1)
					result += ',';
				result += '\n';
			}
			result += indentStr + '}';
			return result;
		}

		return haxe.Json.stringify(obj);
	}

	/**
	 * Converts a psych_v2 JSON object back to a runtime SwagSong with sections.
	 * Called automatically by parseJSON when it detects format = "psych_v2".
	 */
	private static function downgradeFromV2(v2:Dynamic):SwagSong
	{
		var rawChanges:Array<Dynamic> = v2.bpmChanges != null ? cast v2.bpmChanges : [];
		var baseBpm:Float = v2.bpm != null ? v2.bpm : 100.0;
		var bpmChanges:Array<Dynamic> = rawChanges.copy();
		bpmChanges.sort(function(a, b) return Std.int(a.time - b.time));
		if (bpmChanges.length == 0 || bpmChanges[0].time > 0)
			bpmChanges.unshift({time: 0.0, bpm: baseBpm});

		// Returns the active BPM at time t
		var getBpmAt = function(t:Float):Float
		{
			var bpm:Float = baseBpm;
			for (change in bpmChanges)
			{
				if (change.time <= t + 1)
					bpm = change.bpm;
				else
					break;
			}
			return bpm;
		};

		var flatNotes:Array<Dynamic> = v2.notes != null ? cast v2.notes : [];
		var flatEvents:Array<Dynamic> = v2.events != null ? cast v2.events : [];

		// Find the time of the last note
		var lastTime:Float = 0;
		for (note in flatNotes)
		{
			var end:Float = note.t + (note.l != null && note.l > 0 ? note.l : 0.0);
			if (end > lastTime)
				lastTime = end;
		}
		if (lastTime <= 0)
			lastTime = (60000.0 / baseBpm) * 4;

		// Build section start times (4 beats per section in v2)
		var sectionTimes:Array<Float> = [];
		var t:Float = 0;
		while (t <= lastTime + 1)
		{
			sectionTimes.push(t);
			t += (60000.0 / getBpmAt(t)) * 4;
		}

		// Separate Camera Focus events to reconstruct mustHitSection
		var cameraEvents:Array<Dynamic> = flatEvents.filter(function(e) return e.name == 'Camera Focus');
		var otherEvents:Array<Dynamic> = flatEvents.filter(function(e) return e.name != 'Camera Focus');
		cameraEvents.sort(function(a, b) return Std.int(a.t - b.t));

		var sectionMustHits:Array<Bool> = [];
		var camIdx:Int = 0;
		var lastMustHit:Bool = false;
		for (i in 0...sectionTimes.length)
		{
			var secStart:Float = sectionTimes[i];
			var secEnd:Float = (i + 1 < sectionTimes.length) ? sectionTimes[i + 1] : Math.POSITIVE_INFINITY;
			while (camIdx < cameraEvents.length && cameraEvents[camIdx].t < secEnd)
			{
				var cam:Dynamic = cameraEvents[camIdx++];
				if (cam.t >= secStart)
					lastMustHit = Std.string(cam.v.target) == 'player';
			}
			sectionMustHits.push(lastMustHit);
		}

		// Build sections
		var sections:Array<SwagSection> = [];
		var lastBpm:Float = baseBpm;
		for (i in 0...sectionTimes.length)
		{
			var bpm:Float = getBpmAt(sectionTimes[i]);
			var sec:SwagSection = {
				sectionNotes: [],
				sectionBeats: 4.0,
				mustHitSection: sectionMustHits[i]
			};
			if (bpm != lastBpm)
			{
				sec.changeBPM = true;
				sec.bpm = bpm;
				lastBpm = bpm;
			}
			sections.push(sec);
		}

		// Distribute flat notes into the correct section
		for (note in flatNotes)
		{
			var secIdx:Int = sectionTimes.length - 1;
			for (i in 0...sectionTimes.length - 1)
			{
				if (sectionTimes[i + 1] > note.t)
				{
					secIdx = i;
					break;
				}
			}
			if (secIdx >= 0 && secIdx < sections.length)
			{
				var noteArr:Array<Dynamic> = [note.t, note.d, note.l != null ? note.l : 0.0];
				var noteType:Dynamic = note.type;
				if (noteType != null && Std.string(noteType).length > 0)
					noteArr.push(Std.string(noteType));
				sections[secIdx].sectionNotes.push(noteArr);
			}
		}

		// Rebuild v1 events from other events: group by time → [[time, [[name,v1,v2], ...]], ...]
		var evGroups:Map<String, Array<Array<Dynamic>>> = [];
		var evTimes:Array<Float> = [];
		for (ev in otherEvents)
		{
			var key:String = Std.string(ev.t);
			var val1:String = (ev.v != null && ev.v.val1 != null) ? Std.string(ev.v.val1) : '';
			var val2:String = (ev.v != null && ev.v.val2 != null) ? Std.string(ev.v.val2) : '';
			var val3:String = (ev.v != null && ev.v.val3 != null) ? Std.string(ev.v.val3) : '';
			var val4:String = (ev.v != null && ev.v.val4 != null) ? Std.string(ev.v.val4) : '';

			if (!evGroups.exists(key))
			{
				evGroups.set(key, []);
				evTimes.push(ev.t);
			}

			var eventArr:Array<Dynamic> = [ev.name, val1, val2];
			if (val3 != null && val3.length > 0 || ev.v.val3 != null)
				eventArr.push(val3);
			if (val4 != null && val4.length > 0 || ev.v.val4 != null)
				eventArr.push(val4);

			evGroups.get(key).push(eventArr);
		}
		evTimes.sort(function(a, b) return Std.int(a - b));
		var builtEvents:Array<Dynamic> = [];
		for (et in evTimes)
			builtEvents.push([et, evGroups.get(Std.string(et))]);

		var chars:Dynamic = v2.characters != null ? v2.characters : {};
		var song:SwagSong = {
			song: v2.song,
			notes: sections,
			events: builtEvents,
			bpm: baseBpm,
			needsVoices: v2.needsVoices != null ? v2.needsVoices : true,
			speed: v2.speed != null ? v2.speed : 1.0,
			offset: v2.offset != null ? v2.offset : 0.0,
			player1: chars.player != null ? chars.player : 'bf',
			player2: chars.opponent != null ? chars.opponent : 'dad',
			gfVersion: chars.girlfriend != null ? chars.girlfriend : 'gf',
			stage: v2.stage != null ? v2.stage : 'stage',
			format: 'psych_v1'
		};

		if (v2.arrowSkin != null)
			song.arrowSkin = v2.arrowSkin;
		if (v2.splashSkin != null)
			song.splashSkin = v2.splashSkin;
		if (v2.disableNoteRGB == true)
			song.disableNoteRGB = true;
		if (v2.gameOverChar != null)
			song.gameOverChar = v2.gameOverChar;
		if (v2.gameOverSound != null)
			song.gameOverSound = v2.gameOverSound;
		if (v2.gameOverLoop != null)
			song.gameOverLoop = v2.gameOverLoop;
		if (v2.gameOverEnd != null)
			song.gameOverEnd = v2.gameOverEnd;
		if (v2.useModcharts == true)
			song.useModcharts = true;

		return song;
	}

	public static function chartUsesExtendedValues(song:SwagSong):Bool
	{
		if (song == null || song.events == null)
			return false;

		for (eventGroup in song.events)
		{
			if (eventGroup == null || eventGroup.length < 2)
				continue;

			var events:Array<Dynamic> = eventGroup[1];
			if (events == null)
				continue;

			for (event in events)
			{
				if (event != null && event.length > 3)
					return true;
			}
		}
		return false;
	}
}


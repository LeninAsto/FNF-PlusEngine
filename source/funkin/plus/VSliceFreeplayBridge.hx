package funkin.plus;

import backend.Mods;
import backend.Paths;
import flixel.util.FlxColor;
import haxe.Json;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

typedef VSliceFreeplaySong =
{
	var songId:String;
	var displayName:String;
	var modDir:String;
	var levelId:String;
	var icon:String;
	var color:Int;
	var difficulties:Array<String>;
	var variation:String;
	var ?rootPath:String;
	var ?instrumental:String;
	var ?previewStartSeconds:Null<Float>;
	var ?previewEndSeconds:Null<Float>;
}

/**
 * Lightweight scanner used by Plus/Psych freeplay.
 * It reads enough VSlice metadata to list songs without booting Polymod scripts.
 */
class VSliceFreeplayBridge
{
	static inline function traceFreeplay(message:String):Void
	{
		#if (debug || VSLICE_FREEPLAY_TRACE)
		trace('[VSliceFreeplayTrace] $message');
		#end
	}

	public static function listSongs():Array<VSliceFreeplaySong>
	{
		var result:Array<VSliceFreeplaySong> = [];
		#if sys
		traceFreeplay('listSongs begin cwd="${Sys.getCwd()}"');
		#else
		traceFreeplay('listSongs begin no-sys');
		#end
		#if (FEATURE_POLYMOD_MODS && MODS_ALLOWED && sys)
		var seen:Map<String, Bool> = [];
		var enabledDirs:Array<String> = VSliceRuntime.getEnabledVSliceModDirs();
		traceFreeplay('enabled vslice dirs=${enabledDirs.join(",")}');
		for (modDir in enabledDirs)
		{
			var modRoot:String = Paths.vsliceMods(modDir);
			traceFreeplay('mod="$modDir" root="$modRoot" exists=${FileSystem.exists(modRoot)} isDir=${FileSystem.exists(modRoot) && FileSystem.isDirectory(modRoot)}');
			if (!FileSystem.exists(modRoot) || !FileSystem.isDirectory(modRoot)) continue;

			collectLevelSongs(result, seen, modDir, modRoot);
			collectLooseSongs(result, seen, modDir, modRoot);
		}
		traceFreeplay('listSongs result=${result.length}');
		#else
		traceFreeplay('listSongs skipped: FEATURE_POLYMOD_MODS/MODS_ALLOWED/sys not available');
		#end
		return result;
	}

	public static function play(song:VSliceFreeplaySong, difficultyIndex:Int):Void
	{
		if (song == null) return;

		var difficulty:String = 'normal';
		if (song.difficulties != null && song.difficulties.length > 0)
		{
			var index:Int = Std.int(Math.max(0, Math.min(difficultyIndex, song.difficulties.length - 1)));
			difficulty = song.difficulties[index];
		}

		if (song.modDir == null || song.modDir.length == 0)
			VSliceRuntime.ensureBaseReady();

		Mods.currentVSliceModDirectory = song.modDir;
		traceFreeplay('play "${song.songId}" difficulty "$difficulty" variation "${song.variation}" from mod "${song.modDir}".');
		try
		{
			VSliceRuntime.loadPlayState(song.songId, difficulty, song.variation);
		}
		catch (e:Dynamic)
		{
			trace('[VSliceFreeplayBridge] Failed to play "${song.songId}": $e');
			flixel.FlxG.switchState(() -> states.FreeplayStateSelector.create());
		}
	}

	#if (FEATURE_POLYMOD_MODS && MODS_ALLOWED && sys)
	static function collectLevelSongs(result:Array<VSliceFreeplaySong>, seen:Map<String, Bool>, modDir:String, modRoot:String):Void
	{
		var levelsRoot:String = haxe.io.Path.join([modRoot, 'data', 'levels']);
		traceFreeplay('collectLevelSongs mod="$modDir" levelsRoot="$levelsRoot" exists=${FileSystem.exists(levelsRoot)}');
		if (!FileSystem.exists(levelsRoot)) return;

		var levelFiles:Array<String> = sortedJsonFiles(levelsRoot);
		traceFreeplay('level files mod="$modDir" count=${levelFiles.length}');
		for (levelFile in levelFiles)
		{
			try
			{
				var level:Dynamic = Json.parse(File.getContent(levelFile));
				var songs:Array<Dynamic> = cast Reflect.field(level, 'songs');
				if (songs == null)
				{
					traceFreeplay('level "$levelFile" has no songs field');
					continue;
				}

				var levelId:String = haxe.io.Path.withoutExtension(haxe.io.Path.withoutDirectory(levelFile));
				var color:Int = parseColor(Reflect.field(level, 'background'), 0xFF9271FD);
				traceFreeplay('level "$levelId" songs=${songs.length}');

				for (songValue in songs)
				{
					var songId:String = Std.string(songValue);
					addSongVariations(result, seen, modDir, modRoot, songId, levelId, color);
				}
			}
			catch (e:Dynamic)
			{
				trace('[VSliceFreeplayBridge] Failed to parse level $levelFile: $e');
			}
		}
	}

	static function collectLooseSongs(result:Array<VSliceFreeplaySong>, seen:Map<String, Bool>, modDir:String, modRoot:String):Void
	{
		var songsRoot:String = haxe.io.Path.join([modRoot, 'data', 'songs']);
		traceFreeplay('collectLooseSongs mod="$modDir" songsRoot="$songsRoot" exists=${FileSystem.exists(songsRoot)}');
		if (!FileSystem.exists(songsRoot)) return;

		var metadataFiles:Array<String> = findMetadataFiles(songsRoot);
		traceFreeplay('loose metadata mod="$modDir" count=${metadataFiles.length}');
		for (metadataPath in metadataFiles)
		{
			var variationInfo = parseMetadataFileName(metadataPath);
			if (variationInfo != null)
			{
				addSong(result, seen, modDir, modRoot, variationInfo.songId, 'vslice', 0xFF9271FD, variationInfo.variation);
			}
		}
	}

	static function addSongVariations(result:Array<VSliceFreeplaySong>, seen:Map<String, Bool>, modDir:String, modRoot:String, songId:String, levelId:String, color:Int):Void
	{
		var songRoot:String = haxe.io.Path.join([modRoot, 'data', 'songs', songId]);
		var variations:Array<String> = [];
		var metadataFiles:Array<String> = sortedJsonFiles(songRoot);
		traceFreeplay('addSongVariations mod="$modDir" song="$songId" level="$levelId" songRoot="$songRoot" metadataCount=${metadataFiles.length}');
		for (metadataPath in metadataFiles)
		{
			var variationInfo = parseMetadataFileName(metadataPath);
			if (variationInfo != null && variationInfo.songId == songId && variationInfo.variation != 'default' && !variations.contains(variationInfo.variation))
				variations.push(variationInfo.variation);
		}

		if (hasPlayableSongFile(modRoot, songId, 'default') || variations.length == 0)
			addSong(result, seen, modDir, modRoot, songId, levelId, color, 'default');

		for (variation in variations)
			addSong(result, seen, modDir, modRoot, songId, levelId, color, variation);
	}

	static function addSong(result:Array<VSliceFreeplaySong>, seen:Map<String, Bool>, modDir:String, modRoot:String, songId:String, levelId:String, color:Int,
			variation:String):Void
	{
		if (songId == null || songId.trim().length == 0) return;
		if (variation == null || variation.trim().length == 0) variation = 'default';

		var key:String = '$modDir|$songId|$variation';
		if (seen.exists(key))
		{
			traceFreeplay('skip duplicate "$key"');
			return;
		}

		var metadata:Dynamic = loadMetadata(modRoot, songId, variation);
		if (metadata == null)
		{
			traceFreeplay('skip "$key": metadata null');
			return;
		}

		var playData:Dynamic = Reflect.field(metadata, 'playData');
		var characters:Dynamic = playData != null ? Reflect.field(playData, 'characters') : null;
		var opponent:String = fieldString(characters, 'opponent', 'face');
		var icon:String = resolveHealthIconId(modRoot, opponent);
		var displayName:String = fieldString(metadata, 'songName', songId);
		var difficulties:Array<String> = parseDifficulties(Reflect.field(playData, 'difficulties'));
		var metaColor:Int = parseColor(Reflect.field(metadata, 'color'), color);
		var instrumental:String = fieldString(characters, 'instrumental', '');
		var previewStart:Null<Float> = parseOptionalSeconds(firstDynamic(playData, ['freeplayPrevStart', 'previewStart', 'songPreviewStart']));
		var previewEnd:Null<Float> = parseOptionalSeconds(firstDynamic(playData, ['freeplayPrevEnd', 'previewEnd', 'songPreviewEnd']));

		seen.set(key, true);
		traceFreeplay('add song key="$key" display="$displayName" icon="$icon" diffs=${difficulties.join(",")} root="$modRoot"');
		result.push({
			songId: songId,
			displayName: displayName,
			modDir: modDir,
			levelId: levelId,
			icon: icon,
			color: metaColor,
			difficulties: difficulties,
			variation: variation,
			rootPath: modRoot,
			instrumental: instrumental,
			previewStartSeconds: previewStart,
			previewEndSeconds: previewEnd
		});
	}

	public static function resolveInstPath(song:VSliceFreeplaySong):Null<String>
	{
		if (song == null || song.modDir == null || song.songId == null) return null;

		var rootPath:String = song.rootPath;
		if (rootPath == null || rootPath.length == 0)
			rootPath = (song.modDir == null || song.modDir.length == 0) ? haxe.io.Path.join([Sys.getCwd(), 'assets', 'funkin']) : Paths.vsliceMods(song.modDir);

		var songRoot:String = haxe.io.Path.join([rootPath, 'songs', song.songId]);
		var suffixes:Array<String> = [];
		addAudioSuffix(suffixes, song.instrumental);
		if (song.variation != null && song.variation != 'default' && song.variation != 'erect')
			addAudioSuffix(suffixes, song.variation);

		for (suffix in suffixes)
		{
			var path:Null<String> = findExistingInst(songRoot, '-$suffix');
			if (path != null) return path;
		}

		return findExistingInst(songRoot, '');
	}

	static function addAudioSuffix(suffixes:Array<String>, value:String):Void
	{
		if (value == null) return;
		var suffix:String = value.trim();
		if (suffix.length > 0 && !suffixes.contains(suffix)) suffixes.push(suffix);
	}

	static function findExistingInst(songRoot:String, suffix:String):Null<String>
	{
		for (ext in ['ogg', 'mp3', 'wav'])
		{
			var path:String = haxe.io.Path.join([songRoot, 'Inst$suffix.$ext']);
			if (FileSystem.exists(path)) return path;
		}
		return null;
	}

	static function parseMetadataFileName(metadataPath:String):Null<{songId:String, variation:String}>
	{
		var fileName:String = haxe.io.Path.withoutExtension(haxe.io.Path.withoutDirectory(metadataPath));
		var directoryName:String = haxe.io.Path.withoutDirectory(haxe.io.Path.directory(metadataPath));
		var baseSuffix:String = '-metadata';
		if (fileName == '$directoryName$baseSuffix')
		{
			return {songId: directoryName, variation: 'default'};
		}

		var prefix:String = '$directoryName$baseSuffix-';
		if (fileName.startsWith(prefix))
		{
			return {songId: directoryName, variation: fileName.substr(prefix.length)};
		}

		return null;
	}

	static function loadMetadata(modRoot:String, songId:String, variation:String):Dynamic
	{
		var songRoot:String = haxe.io.Path.join([modRoot, 'data', 'songs', songId]);
		var suffix:String = variation == null || variation == 'default' ? '' : '-$variation';
		var path:String = haxe.io.Path.join([songRoot, '$songId-metadata$suffix.json']);
		if (!FileSystem.exists(path) && suffix.length > 0)
			path = haxe.io.Path.join([songRoot, '$songId-metadata.json']);
		if (!FileSystem.exists(path))
		{
			traceFreeplay('metadata missing song="$songId" variation="$variation" path="$path"');
			return null;
		}

		try
		{
			return Json.parse(File.getContent(path));
		}
		catch (e:Dynamic)
		{
			trace('[VSliceFreeplayBridge] Failed metadata $path: $e');
			return null;
		}
	}

	static function hasPlayableSongFile(modRoot:String, songId:String, variation:String):Bool
	{
		var songRoot:String = haxe.io.Path.join([modRoot, 'data', 'songs', songId]);
		var suffix:String = variation == null || variation == 'default' ? '' : '-$variation';
		return FileSystem.exists(haxe.io.Path.join([songRoot, '$songId-metadata$suffix.json']))
			|| FileSystem.exists(haxe.io.Path.join([songRoot, '$songId-chart$suffix.json']));
	}

	static function resolveHealthIconId(modRoot:String, characterId:String):String
	{
		if (characterId == null || characterId.trim().length == 0) return 'face';

		var charPath:String = haxe.io.Path.join([modRoot, 'data', 'characters', '$characterId.json']);
		if (FileSystem.exists(charPath))
		{
			try
			{
				var data:Dynamic = Json.parse(File.getContent(charPath));
				var healthIcon:Dynamic = Reflect.field(data, 'healthIcon');
				var iconId:String = fieldString(healthIcon, 'id', characterId);
				if (iconId.length > 0) return iconId;
			}
			catch (e:Dynamic) {}
		}

		return characterId;
	}

	static function parseDifficulties(value:Dynamic):Array<String>
	{
		var result:Array<String> = [];
		if (value != null)
		{
			try
			{
				var values:Array<Dynamic> = cast value;
				for (item in values)
				{
					var diff:String = Std.string(item).trim();
					if (diff.length > 0 && !result.contains(diff)) result.push(diff);
				}
			}
			catch (e:Dynamic) {}
		}

		if (result.length == 0) result.push('normal');
		return result;
	}

	static function parseColor(value:Dynamic, fallback:Int):Int
	{
		if (value == null) return fallback;

		if (Std.isOfType(value, String))
		{
			var text:String = Std.string(value).trim();
			if (text.startsWith('#')) text = '0xFF' + text.substr(1);
			try
			{
				var parsed:Null<FlxColor> = FlxColor.fromString(text);
				return parsed != null ? parsed : fallback;
			}
			catch (e:Dynamic)
			{
				return fallback;
			}
		}

		try
		{
			var values:Array<Dynamic> = cast value;
			if (values != null && values.length >= 3)
				return FlxColor.fromRGB(Std.parseInt(Std.string(values[0])), Std.parseInt(Std.string(values[1])), Std.parseInt(Std.string(values[2])));
		}
		catch (e:Dynamic) {}

		return fallback;
	}

	static function fieldString(object:Dynamic, field:String, fallback:String):String
	{
		if (object != null && Reflect.hasField(object, field))
		{
			var value:Dynamic = Reflect.field(object, field);
			if (value != null) return Std.string(value);
		}
		return fallback;
	}

	static function firstDynamic(object:Dynamic, fields:Array<String>):Dynamic
	{
		if (object == null) return null;
		for (field in fields)
		{
			if (Reflect.hasField(object, field))
			{
				var value:Dynamic = Reflect.field(object, field);
				if (value != null) return value;
			}
		}
		return null;
	}

	static function parseOptionalSeconds(value:Dynamic):Null<Float>
	{
		if (value == null) return null;
		var parsed:Float = Std.parseFloat(Std.string(value));
		if (Math.isNaN(parsed) || parsed < 0) return null;
		return parsed > 1000 ? parsed / 1000 : parsed;
	}

	static function sortedJsonFiles(path:String):Array<String>
	{
		var result:Array<String> = [];
		if (!FileSystem.exists(path)) return result;

		for (item in FileSystem.readDirectory(path))
		{
			var child:String = haxe.io.Path.join([path, item]);
			if (!FileSystem.isDirectory(child) && item.toLowerCase().endsWith('.json'))
				result.push(child);
		}
		result.sort(Reflect.compare);
		return result;
	}

	static function findMetadataFiles(path:String):Array<String>
	{
		var result:Array<String> = [];
		if (!FileSystem.exists(path)) return result;

		for (item in FileSystem.readDirectory(path))
		{
			var child:String = haxe.io.Path.join([path, item]);
			if (FileSystem.isDirectory(child))
			{
				result = result.concat(findMetadataFiles(child));
			}
			else if (item.toLowerCase().indexOf('-metadata') != -1 && item.toLowerCase().endsWith('.json'))
			{
				result.push(child);
			}
		}
		result.sort(Reflect.compare);
		return result;
	}
	#end
}

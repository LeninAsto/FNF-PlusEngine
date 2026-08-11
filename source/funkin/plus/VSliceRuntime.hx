package funkin.plus;

import backend.Mods;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxState;
import funkin.PlayerSettings;
import funkin.Preferences;
import funkin.data.character.CharacterData.CharacterDataParser;
import funkin.data.dialogue.ConversationRegistry;
import funkin.data.dialogue.DialogueBoxRegistry;
import funkin.data.dialogue.SpeakerRegistry;
import funkin.data.event.SongEventRegistry;
import funkin.data.freeplay.album.AlbumRegistry;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.data.freeplay.style.FreeplayStyleRegistry;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.data.song.SongRegistry;
import funkin.data.stage.StageRegistry;
import funkin.data.stickers.StickerRegistry;
import funkin.data.story.level.LevelRegistry;
import funkin.modding.PolymodHandler;
import funkin.modding.module.ModuleHandler;
import funkin.play.PlayState;
import funkin.play.PlayState.PlayStateParams;
import funkin.play.PlayStatePlaylist;
import funkin.play.song.Song;
import funkin.play.notes.notekind.NoteKindManager;
import funkin.save.Save;
import funkin.ui.transition.LoadingState;
import funkin.util.Constants;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

/**
 * Plus Engine bridge for the official VSlice runtime.
 * Keeps classic Plus/Psych mods on the legacy path and boots VSlice only for mods
 * that expose official VSlice/Polymod layout markers.
 */
class VSliceRuntime
{
	public static var active(default, null):Bool = false;

	static var initialized:Bool = false;
	static var loadedSignature:String = '';
	static var saveInitialized:Bool = false;

	public static function shouldUseVSliceRuntime():Bool
	{
		return getEnabledVSliceModDirs().length > 0;
	}

	public static function routeOfficialMenusToPlus():Bool
	{
		return shouldUseVSliceRuntime();
	}

	public static function createFreeplayState():FlxState
	{
		ensureReady();
		return funkin.ui.freeplay.FreeplayState.build();
	}

	public static function createStoryMenuState():FlxState
	{
		ensureReady();
		return new funkin.ui.story.StoryMenuState();
	}

	public static function createOptionsState(?pageId:String):FlxState
	{
		ensureReady();
		funkin.ui.options.OptionsState.requestedInitialPage = pageId;
		funkin.ui.options.OptionsState.returnToPlusOptions = true;
		return new funkin.ui.options.OptionsState();
	}

	public static function loadPlayState(songId:String, difficulty:String = 'normal', variation:String = 'default'):Void
	{
		ensureReady();
		if (difficulty == null || difficulty.trim().length == 0) difficulty = Constants.DEFAULT_DIFFICULTY;
		if (variation == null || variation.trim().length == 0) variation = Constants.DEFAULT_VARIATION;
		variation = resolveRequestedVariationFromCurrentMod(songId, variation);

		var targetSong:Null<Song> = SongRegistry.instance.fetchEntry(songId, {variation: variation});
		if (targetSong == null && variation != Constants.DEFAULT_VARIATION)
		{
			variation = Constants.DEFAULT_VARIATION;
			targetSong = SongRegistry.instance.fetchEntry(songId, {variation: variation});
		}
		if (targetSong == null)
		{
			trace('VSliceRuntime could not find song "$songId"; returning to Plus freeplay.');
			FlxG.switchState(() -> states.FreeplayStateSelector.create());
			return;
		}

		variation = resolveVariationForDifficulty(targetSong, difficulty, variation);
		trace('VSliceRuntime loading song "$songId" difficulty "$difficulty" variation "$variation"');

		var targetDifficulty = targetSong.getDifficulty(difficulty, variation);
		if (targetDifficulty == null && variation != Constants.DEFAULT_VARIATION)
		{
			variation = Constants.DEFAULT_VARIATION;
			targetDifficulty = targetSong.getDifficulty(difficulty, variation);
		}
		if (targetDifficulty == null)
		{
			trace('VSliceRuntime could not find chart data for "$songId" difficulty "$difficulty" variation "$variation"; returning to Plus freeplay.');
			FlxG.switchState(() -> states.FreeplayStateSelector.create());
			return;
		}

		PlayStatePlaylist.reset();
		PlayStatePlaylist.isStoryMode = false;
		PlayStatePlaylist.campaignDifficulty = difficulty;
		funkin.Paths.setCurrentLevel(null);

		var params:PlayStateParams = {
			targetSong: targetSong,
			targetDifficulty: difficulty,
			targetVariation: variation,
			practiceMode: VSlicePreferencesBridge.practiceMode(),
			botPlayMode: VSlicePreferencesBridge.botPlayMode(),
			playbackRate: VSlicePreferencesBridge.playbackRate()
		};

		LoadingState.loadPlayState(params, true);
	}

	static function resolveRequestedVariationFromCurrentMod(songId:String, requestedVariation:String):String
	{
		if (requestedVariation == null || requestedVariation.trim().length == 0) requestedVariation = Constants.DEFAULT_VARIATION;
		if (requestedVariation != Constants.DEFAULT_VARIATION) return requestedVariation;

		#if (MODS_ALLOWED && sys)
		if (songId == null || songId.trim().length == 0) return requestedVariation;

		var candidateModDirs:Array<String> = [];
		var currentModDir:String = Mods.currentVSliceModDirectory;
		if (currentModDir != null && currentModDir.trim().length > 0) candidateModDirs.push(currentModDir);
		for (enabledModDir in getEnabledVSliceModDirs())
		{
			if (enabledModDir != null && enabledModDir.trim().length > 0 && !candidateModDirs.contains(enabledModDir))
				candidateModDirs.push(enabledModDir);
		}

		for (modDir in candidateModDirs)
		{
			var resolved:Null<String> = findImplicitOnlyVariationInMod(songId, modDir);
			if (resolved != null) return resolved;
		}
		#end

		return requestedVariation;
	}

	#if (MODS_ALLOWED && sys)
	static function findImplicitOnlyVariationInMod(songId:String, modDir:String):Null<String>
	{
		var modRoot:String = haxe.io.Path.join([modsRoot(), modDir]);
		var songRoot:String = haxe.io.Path.join([modRoot, 'data', 'songs', songId]);
		if (!FileSystem.exists(songRoot) || !FileSystem.isDirectory(songRoot)) return null;

		if (FileSystem.exists(haxe.io.Path.join([songRoot, '$songId-metadata.json']))
			|| FileSystem.exists(haxe.io.Path.join([songRoot, '$songId-chart.json'])))
			return null;

		var variations:Array<String> = [];
		for (item in FileSystem.readDirectory(songRoot))
		{
			var lower:String = item.toLowerCase();
			var metadataPrefix:String = '$songId-metadata-'.toLowerCase();
			var chartPrefix:String = '$songId-chart-'.toLowerCase();
			var variation:Null<String> = null;
			if (lower.startsWith(metadataPrefix) && lower.endsWith('.json'))
				variation = item.substr(metadataPrefix.length, item.length - metadataPrefix.length - '.json'.length);
			else if (lower.startsWith(chartPrefix) && lower.endsWith('.json'))
				variation = item.substr(chartPrefix.length, item.length - chartPrefix.length - '.json'.length);

			if (variation != null && variation.length > 0 && !variations.contains(variation)) variations.push(variation);
		}

		if (variations.length == 1)
		{
			trace('VSliceRuntime resolved "$songId" default variation to "${variations[0]}" from mod "$modDir".');
			return variations[0];
		}

		return null;
	}
	#end

	static function resolveVariationForDifficulty(song:Song, difficulty:String, requestedVariation:String):String
	{
		if (song == null) return requestedVariation ?? Constants.DEFAULT_VARIATION;
		if (difficulty == null || difficulty.trim().length == 0) difficulty = Constants.DEFAULT_DIFFICULTY;
		if (requestedVariation == null || requestedVariation.trim().length == 0) requestedVariation = Constants.DEFAULT_VARIATION;

		// Erect/Nightmare charts are stored as the `erect` variation in official VSlice.
		// Plus freeplay can sometimes preserve the default variation while only changing
		// the difficulty, so force the matching VSlice variation when it exists.
		if ((difficulty == 'erect' || difficulty == 'nightmare') && song.hasDifficulty(difficulty, 'erect'))
		{
			return 'erect';
		}

		if (song.hasDifficulty(difficulty, requestedVariation)) return requestedVariation;

		var validVariation:Null<String> = song.getFirstValidVariation(difficulty);
		if (validVariation != null) return validVariation;

		if (requestedVariation != Constants.DEFAULT_VARIATION && song.hasDifficulty(difficulty, Constants.DEFAULT_VARIATION))
			return Constants.DEFAULT_VARIATION;

		return requestedVariation;
	}

	public static function ensureReady():Void
	{
		var dirs:Array<String> = getEnabledVSliceModDirs();
		var signature:String = dirs.join('|');
		if (initialized && loadedSignature == signature)
		{
			active = true;
			VSlicePreferencesBridge.syncFromPlus();
			VSlicePreferencesBridge.syncControlsFromPlus();
			return;
		}

		active = dirs.length > 0;
		if (!active) return;

		if (!saveInitialized)
		{
			try
			{
				Save.load();
			}
			catch (e:Dynamic)
			{
				VSliceDebugLog.error('VSlice Save Error', 'Failed to load VSlice save, continuing with defaults: ${Std.string(e)}');
			}
			saveInitialized = true;
		}
		Preferences.init();
		VSlicePreferencesBridge.syncFromPlus();
		if (PlayerSettings.player1 == null) PlayerSettings.init();
		VSlicePreferencesBridge.syncControlsFromPlus();

		PolymodHandler.loadModsByDir(dirs);
		reloadRegistries();

		initialized = true;
		loadedSignature = signature;
	}

	public static function getEnabledVSliceModDirs():Array<String>
	{
		var result:Array<String> = [];
		#if MODS_ALLOWED
		for (dir in Mods.parseVSliceList().enabled)
		{
			if (isVSliceMod(dir)) result.push(dir);
		}
		#end
		return result;
	}

	public static function refreshLoadedModsFromMenu():Void
	{
		#if FEATURE_POLYMOD_MODS
		var dirs:Array<String> = getEnabledVSliceModDirs();
		var signature:String = dirs.join('|');

		active = dirs.length > 0;
		initialized = false;
		loadedSignature = null;

		ModuleHandler.clearModuleCache();
		polymod.Polymod.clearScripts();
		PolymodHandler.loadModsByDir(dirs);
		reloadRegistries();

		initialized = true;
		loadedSignature = signature;
		#end
	}

	public static function listOptionCategories():Array<VSliceOptionCategory>
	{
		var result:Array<VSliceOptionCategory> = [];
		#if sys
		var seen:Map<String, Bool> = [];
		for (dir in getEnabledVSliceModDirs())
		{
			var root:String = haxe.io.Path.join([modsRoot(), dir]);
			var optionsRoot:String = haxe.io.Path.join([root, 'scripts', 'modules', 'options']);
			var files:Array<String> = [];
			collectFiles(optionsRoot, '.hxc', files);
			if (files.length == 0) continue;

			var modName:String = readModDisplayName(root, dir);
			var pageId:String = null;
			var label:String = null;

			for (file in files)
			{
				var text:String = safeRead(file);
				if (text == null) continue;
				if (pageId == null) pageId = firstMatch(text, ~/addPage\s*\(\s*["']([^"']+)["']/);
				if (label == null) label = firstMatch(text, ~/createItem\s*\(\s*["']([^"']+)["']/);
				if (pageId != null && label != null) break;
			}

			if (pageId == null) pageId = dir;
			if (label == null) label = '$modName Options';
			if (seen.exists(pageId)) continue;
			seen.set(pageId, true);

			result.push({
				modDir: dir,
				pageId: pageId,
				label: label
			});
		}
		#end
		return result;
	}

	public static function isTopModVSlice():Bool
	{
		#if MODS_ALLOWED
		var enabled:Array<String> = Mods.parseVSliceList().enabled;
		return enabled.length > 0 && isVSliceMod(enabled[0]);
		#else
		return false;
		#end
	}

	public static function isVSliceMod(dir:String):Bool
	{
		#if sys
		if (dir == null || dir.trim().length == 0) return false;
		var root:String = haxe.io.Path.join([modsRoot(), dir]);
		if (!FileSystem.exists(root) || !FileSystem.isDirectory(root)) return false;

		if (FileSystem.exists(haxe.io.Path.join([root, '_polymod_meta.json']))) return true;
		if (hasFileEnding(haxe.io.Path.join([root, 'scripts']), '.hxc')) return true;
		if (hasFileEnding(haxe.io.Path.join([root, 'data', 'songs']), '-metadata.json')) return true;
		if (hasJsonIn(haxe.io.Path.join([root, 'data', 'characters']))) return true;
		if (hasJsonIn(haxe.io.Path.join([root, 'data', 'stages']))) return true;
		if (hasJsonIn(haxe.io.Path.join([root, 'data', 'notestyles']))) return true;
		if (hasJsonIn(haxe.io.Path.join([root, 'data', 'levels']))) return true;
		#end
		return false;
	}

	static function reloadRegistries():Void
	{
		SongEventRegistry.loadEventCache();
		SongRegistry.instance.loadEntries();
		LevelRegistry.instance.loadEntries();
		NoteStyleRegistry.instance.loadEntries();
		PlayerRegistry.instance.loadEntries();
		ConversationRegistry.instance.loadEntries();
		DialogueBoxRegistry.instance.loadEntries();
		SpeakerRegistry.instance.loadEntries();
		FreeplayStyleRegistry.instance.loadEntries();
		AlbumRegistry.instance.loadEntries();
		StageRegistry.instance.loadEntries();
		StickerRegistry.instance.loadEntries();
		CharacterDataParser.loadCharacterCache();
		PlayerRegistry.instance.refreshOwnedCharacterIds();

		NoteKindManager.initialize();
		ModuleHandler.buildModuleCallbacks();
		ModuleHandler.loadModuleCache();
		ModuleHandler.callOnCreate();
	}

	#if sys
	static function modsRoot():String
	{
		#if MODS_ALLOWED
		return Paths.vsliceMods();
		#else
		return haxe.io.Path.join([Sys.getCwd(), 'mods']);
		#end
	}

	static function hasJsonIn(path:String):Bool
	{
		return hasFileEnding(path, '.json');
	}

	static function hasFileEnding(path:String, suffix:String):Bool
	{
		if (!FileSystem.exists(path)) return false;

		try
		{
			if (!FileSystem.isDirectory(path)) return path.toLowerCase().endsWith(suffix);

			for (item in FileSystem.readDirectory(path))
			{
				var child:String = haxe.io.Path.join([path, item]);
				if (FileSystem.isDirectory(child))
				{
					if (hasFileEnding(child, suffix)) return true;
				}
				else if (item.toLowerCase().endsWith(suffix))
				{
					return true;
				}
			}
		}
		catch (e:Dynamic)
		{
			trace('VSliceRuntime marker scan failed at $path: $e');
		}

		return false;
	}

	static function collectFiles(path:String, suffix:String, result:Array<String>):Void
	{
		if (!FileSystem.exists(path)) return;

		try
		{
			if (!FileSystem.isDirectory(path))
			{
				if (path.toLowerCase().endsWith(suffix)) result.push(path);
				return;
			}

			for (item in FileSystem.readDirectory(path))
			{
				var child:String = haxe.io.Path.join([path, item]);
				if (FileSystem.isDirectory(child))
					collectFiles(child, suffix, result);
				else if (item.toLowerCase().endsWith(suffix))
					result.push(child);
			}
		}
		catch (e:Dynamic)
		{
			trace('VSliceRuntime options scan failed at $path: $e');
		}
	}

	static function readModDisplayName(root:String, fallback:String):String
	{
		var metaPath:String = haxe.io.Path.join([root, '_polymod_meta.json']);
		if (!FileSystem.exists(metaPath)) return fallback;

		try
		{
			var meta:Dynamic = haxe.Json.parse(File.getContent(metaPath));
			var title:Dynamic = Reflect.field(meta, 'title');
			if (title == null) title = Reflect.field(meta, 'name');
			if (title == null) title = Reflect.field(meta, 'id');
			if (title != null && Std.string(title).trim().length > 0) return Std.string(title);
		}
		catch (e:Dynamic) {}

		return fallback;
	}

	static function safeRead(path:String):Null<String>
	{
		try
		{
			return File.getContent(path);
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	static function firstMatch(text:String, regex:EReg):Null<String>
	{
		if (text != null && regex.match(text)) return regex.matched(1);
		return null;
	}
	#end
}

typedef VSliceOptionCategory =
{
	var modDir:String;
	var pageId:String;
	var label:String;
}

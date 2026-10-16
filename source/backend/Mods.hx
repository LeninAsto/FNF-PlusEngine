package backend;

import backend.AssetLoader;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import haxe.Json;
import lime.app.Application;
import lime.graphics.Image;

#if sys
import sys.FileSystem;
#end

using StringTools;

typedef ModsList =
{
	enabled:Array<String>,
	disabled:Array<String>,
	all:Array<String>
};

class Mods
{
	static public var currentModDirectory:String = '';
	static public var launchedMod:String = null;
	public static inline var DEFAULT_WINDOW_TITLE:String = "Friday Night Funkin': Plus Engine";
	public static inline var BASE_GAME_MOD_FOLDER:String = "Friday Night Funkin";
	public static inline var BASE_GAME_LOCAL_FOLDER:String = "base_game";
	public static final ignoreModFolders:Array<String> = [
		'characters',
		'custom_events',
		'custom_notetypes',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'achievements'
	];

	private static var globalMods:Array<String> = [];
	inline public static function getGlobalMods()
		return globalMods;

	public static function pushGlobalMods() // prob a better way to do this but idc
	{
		globalMods = [];
		// A launched mod is an isolated runtime context. Keep it first so
		// merged asset lookups and global scripts cannot silently fall back to
		// another enabled mod while that context is active.
		if (launchedMod != null && launchedMod.length > 0)
			pushGlobalMod(launchedMod);
		pushGlobalMod(BASE_GAME_MOD_FOLDER);

		for (mod in parseList().enabled)
		{
			if (isBaseGameMod(mod) || mod == launchedMod)
				continue;

			var pack:Dynamic = getPack(mod);
			if (pack != null && pack.runsGlobally)
				pushGlobalMod(mod);
		}
		return globalMods;
	}

	inline public static function getModDirectories():Array<String>
	{
		var list:Array<String> = [];
		#if MODS_ALLOWED
		var modsFolder:String = Paths.mods();
		if (Paths.safeModPathExists(modsFolder))
		{
			for (folder in Paths.readDirectory(modsFolder))
			{
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (Paths.safeModIsDirectory(path) && !ignoreModFolders.contains(folder.toLowerCase()) && !list.contains(folder))
					list.push(folder);
			}
		}
		#end
		return list;
	}

	inline public static function mergeAllTextsNamed(path:String, ?defaultDirectory:String = null, allowDuplicates:Bool = false)
	{
		if (defaultDirectory == null)
			defaultDirectory = Paths.getSharedPath();
		defaultDirectory = defaultDirectory.trim();
		if (!defaultDirectory.endsWith('/'))
			defaultDirectory += '/';
		if (!defaultDirectory.startsWith('assets/'))
			defaultDirectory = 'assets/$defaultDirectory';

		var mergedList:Array<String> = [];
		var paths:Array<String> = directoriesWithFile(defaultDirectory, path);

		var defaultPath:String = defaultDirectory + path;
		if (paths.contains(defaultPath))
		{
			paths.remove(defaultPath);
			paths.insert(0, defaultPath);
		}

		for (file in paths)
		{
			var list:Array<String> = CoolUtil.coolTextFile(file);
			for (value in list)
				if ((allowDuplicates || !mergedList.contains(value)) && value.length > 0)
					mergedList.push(value);
		}
		return mergedList;
	}

	inline public static function directoriesWithFile(path:String, fileToFind:String, mods:Bool = true)
	{
		var foldersToCheck:Array<String> = [];
		// Main folder
		if (AssetLoader.exists(path + fileToFind, TEXT))
			foldersToCheck.push(path + fileToFind);

		// Week folder
		if (Paths.currentLevel != null && Paths.currentLevel != path)
		{
			var pth:String = Paths.getFolderPath(fileToFind, Paths.currentLevel);
			if (!foldersToCheck.contains(pth) && AssetLoader.exists(pth, TEXT))
				foldersToCheck.push(pth);
		}

		#if MODS_ALLOWED
		if (mods)
		{
			// Global mods first
			for (mod in Mods.getGlobalMods())
			{
				var folder:String = Paths.mods(mod + '/' + fileToFind);
				if (AssetLoader.exists(folder, TEXT) && !foldersToCheck.contains(folder))
					foldersToCheck.push(folder);
			}

			// Then "PsychEngine/mods/" main folder
			var folder:String = Paths.mods(fileToFind);
			if (AssetLoader.exists(folder, TEXT) && !foldersToCheck.contains(folder))
				foldersToCheck.push(Paths.mods(fileToFind));

			// And lastly, the loaded mod's folder
			if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			{
				var folder:String = Paths.mods(Mods.currentModDirectory + '/' + fileToFind);
				if (AssetLoader.exists(folder, TEXT) && !foldersToCheck.contains(folder))
					foldersToCheck.push(folder);
			}
		}
		#end
		return foldersToCheck;
	}

	public static function getPack(?folder:String = null):Dynamic
	{
		#if MODS_ALLOWED
		if (folder == null)
			folder = Mods.currentModDirectory;

		var path = Paths.mods(folder + '/pack.json');
		if (AssetLoader.exists(path, TEXT))
		{
			try
			{
				var rawJson:String = AssetLoader.loadText(path);
				if (rawJson != null && rawJson.length > 0)
					return tjson.TJSON.parse(rawJson);
			}
			catch (e:Dynamic)
			{
				trace(e);
			}
		}
		#end
		return null;
	}

	public static function applyWindowBrand(?folder:String = null):Void
	{
		#if (MODS_ALLOWED && desktop)
		if (folder == null || folder.length < 1)
			folder = launchedMod;
		if (folder == null || folder.length < 1)
		{
			resetWindowBrand();
			return;
		}

		var window = (Application.current != null) ? Application.current.window : null;
		if (window == null)
			return;

		var pack:Dynamic = getPack(folder);
		var title:String = (pack != null && Reflect.hasField(pack, 'windowTitle')) ? Std.string(Reflect.field(pack, 'windowTitle')) : null;
		if (title == null || title.trim().length < 1)
			title = (pack != null && Reflect.hasField(pack, 'name')) ? Std.string(Reflect.field(pack, 'name')) : null;
		window.title = (title != null && title.trim().length > 0) ? title : DEFAULT_WINDOW_TITLE;

		#if sys
		var iconPath:String = Paths.mods(folder + '/icon.ico');
		if (!FileSystem.exists(iconPath))
			iconPath = Paths.mods(folder + '/icon.png');
		if (FileSystem.exists(iconPath))
		{
			try
				window.setIcon(Image.fromFile(iconPath))
			catch (e:Dynamic)
				trace('Failed to apply window icon for "$folder": $e');
		}
		#end
		#end
	}

	public static function resetWindowBrand():Void
	{
		#if desktop
		var window = (Application.current != null) ? Application.current.window : null;
		if (window == null)
			return;

		window.title = DEFAULT_WINDOW_TITLE;
		#if sys
		if (FileSystem.exists('icon.ico'))
		{
			try
				window.setIcon(Image.fromFile('icon.ico'))
			catch (e:Dynamic)
				trace('Failed to reset window icon: $e');
		}
		#end
		#end
	}

	public static var updatedOnState:Bool = false;

	inline public static function parseList():ModsList
	{
		if (!updatedOnState)
			updateModList();
		var list:ModsList = {enabled: [], disabled: [], all: []};

		#if MODS_ALLOWED
		try
		{
			for (mod in CoolUtil.coolTextFile(#if android StorageUtil.getModsListPath() #else Sys.getCwd() + 'modsList.txt' #end))
			{
				// trace('Mod: $mod');
				if (mod.trim().length < 1)
					continue;

				var dat = mod.split("|");
				var folder:String = dat[0];
				var forced:Bool = isRequiredGlobalMod(folder);

				if (!list.all.contains(folder))
					list.all.push(folder);

				if (dat[1] == "1" || forced)
					list.enabled.push(folder);
				else
					list.disabled.push(folder);
			}
		}
		catch (e)
		{
			trace(e);
		}

		ensureRequiredGlobalMods(list);
		#end
		return list;
	}

	public static function saveList(list:ModsList):Void
	{
		var fileStr:String = '';
		for (mod in list.all)
		{
			if (mod.trim().length < 1)
				continue;

			if (fileStr.length > 0)
				fileStr += '\n';

			var on = '1';
			if (list.disabled.contains(mod) && !isRequiredGlobalMod(mod))
				on = '0';
			fileStr += '$mod|$on';
		}

		#if MODS_ALLOWED
		if (requiredBaseGameAvailable() && !list.all.contains(BASE_GAME_MOD_FOLDER))
		{
			if (fileStr.length > 0)
				fileStr += '\n';
			fileStr += BASE_GAME_MOD_FOLDER + '|1';
		}
		#end

		var path:String = #if android StorageUtil.getModsListPath() #else Sys.getCwd() + 'modsList.txt' #end;
		try
		{
			File.saveContent(path, fileStr);
		}
		catch (e:Dynamic)
		{
			trace('[Mods] Failed to save modsList.txt: $e');
		}

		updatedOnState = true;
	}

	public static function updateModList()
	{
		#if MODS_ALLOWED
		// Find all that are already ordered
		var list:Array<Array<Dynamic>> = [];
		var added:Array<String> = [];
		try
		{
			for (mod in CoolUtil.coolTextFile(#if android StorageUtil.getModsListPath() #else Sys.getCwd() + 'modsList.txt' #end))
			{
				var dat:Array<String> = mod.split("|");
				var folder:String = dat[0];
				var folderPath:String = Paths.mods(folder);
				if (folder.trim().length > 0 && Paths.safeModIsDirectory(folderPath) && !added.contains(folder))
				{
					added.push(folder);
					list.push([folder, (dat[1] == "1") || isRequiredGlobalMod(folder)]);
				}
			}
		}
		catch (e)
		{
			trace(e);
		}

		if (requiredBaseGameAvailable() && !added.contains(BASE_GAME_MOD_FOLDER))
		{
			added.push(BASE_GAME_MOD_FOLDER);
			list.push([BASE_GAME_MOD_FOLDER, true]);
		}

		// Scan for folders that aren't on modsList.txt yet
		for (folder in getModDirectories())
		{
			var folderPath:String = Paths.mods(folder);
			if (folder.trim().length > 0
				&& Paths.safeModIsDirectory(folderPath)
				&& !ignoreModFolders.contains(folder.toLowerCase())
				&& !added.contains(folder))
			{
				added.push(folder);
				list.push([folder, true]); // i like it false by default. -bb //Well, i like it True! -Shadow Mario (2022)
				// Shadow Mario (2023): What the fuck was bb thinking
			}
		}

		// Now save file
		var fileStr:String = '';
		for (values in list)
		{
			if (fileStr.length > 0)
				fileStr += '\n';
			fileStr += values[0] + '|' + ((values[1] || isRequiredGlobalMod(values[0])) ? '1' : '0');
		}

		try
		{
			File.saveContent(#if android StorageUtil.getModsListPath() #else Sys.getCwd() + 'modsList.txt' #end, fileStr);
		}
		catch (e:Dynamic)
		{
			trace('Failed to save modsList.txt: $e');
		}
		updatedOnState = true;
		// trace('Saved modsList.txt');
		#end
	}

	public static function loadTopMod()
	{
		#if MODS_ALLOWED
		if (launchedMod != null && launchedMod.length > 0)
		{
			currentModDirectory = launchedMod;
			return;
		}
		#end

		Mods.currentModDirectory = '';

		#if MODS_ALLOWED
		var list:Array<String> = Mods.parseList().enabled;
		if (list != null)
			for (mod in list)
				if (mod != null && mod.length > 0 && !isRequiredGlobalMod(mod))
				{
					Mods.currentModDirectory = mod;
					break;
				}
		#end
	}

	public static function getLaunchState(folder:String):String
	{
		#if MODS_ALLOWED
		var pack:Dynamic = getPack(folder);
		if (pack != null)
		{
			for (field in ['launchState', 'entryState', 'mainState'])
			{
				var value:Dynamic = Reflect.field(pack, field);
				if (value != null)
				{
					var state:String = Std.string(value).trim();
					if (state.length > 0)
						return state;
				}
			}
		}
		#end
		return 'MainMenuState';
	}

	public static inline function getEntryState(folder:String):String
		return getLaunchState(folder);

	public static function getMenuMusic(folder:String):String
	{
		var value:Dynamic = getPackField(folder, 'menuMusic');
		if (value != null)
		{
			var music:String = Std.string(value).trim();
			if (music.length > 0)
				return music;
		}
		return 'freakyMenu';
	}

	public static function getLuaMode(folder:String):String
	{
		var value:Dynamic = getPackField(folder, 'luaMode');
		if (value != null)
		{
			var mode:String = Std.string(value).trim().toLowerCase();
			if (mode == 'raw' || mode == 'compat')
				return mode;
		}
		return 'compat';
	}

	public static function isNativeMobile(folder:String):Bool
		return packBool(folder, 'nativeMobile', false);

	public static function compileScripts(folder:String):Bool
		return packBool(folder, 'compileScripts', false);

	public static function noteCompatibilityMode(folder:String):Bool
		return packBool(folder, 'compatibilityMode', false) || packBool(folder, 'legacyMode', false);

	public static function isLaunchable(folder:String):Bool
	{
		#if (MODS_ALLOWED && sys && HSCRIPT_ALLOWED)
		if (folder == null || folder.trim().length < 1)
			return false;

		var state:String = getLaunchState(folder);
		for (relative in scripting.ScriptRegistry.classPaths(scripting.ScriptRegistry.STATE_PACKAGE + '.' + state))
		{
			var hxPath:String = Paths.mods('$folder/$relative');
			if (Paths.safeModPathExists(hxPath))
				return true;
		}
		#end
		return false;
	}

	static function getPackField(folder:String, field:String):Dynamic
	{
		#if MODS_ALLOWED
		var pack:Dynamic = getPack(folder);
		return pack == null ? null : Reflect.field(pack, field);
		#else
		return null;
		#end
	}

	public static function isBaseGameMod(folder:String):Bool
		return normalizeModFolder(folder) == normalizeModFolder(BASE_GAME_MOD_FOLDER);

	public static function isRequiredGlobalMod(folder:String):Bool
		return isBaseGameMod(folder) && requiredBaseGameAvailable();

	static function ensureRequiredGlobalMods(list:ModsList):Void
	{
		if (!requiredBaseGameAvailable())
			return;

		if (!list.all.contains(BASE_GAME_MOD_FOLDER))
			list.all.push(BASE_GAME_MOD_FOLDER);

		list.disabled.remove(BASE_GAME_MOD_FOLDER);
		if (!list.enabled.contains(BASE_GAME_MOD_FOLDER))
			list.enabled.push(BASE_GAME_MOD_FOLDER);
	}

	static function pushGlobalMod(folder:String):Void
	{
		if (folder == null || folder.length < 1 || !requiredOrInstalled(folder) || globalMods.contains(folder))
			return;

		globalMods.push(folder);
	}

	static function requiredOrInstalled(folder:String):Bool
	{
		#if MODS_ALLOWED
		if (isBaseGameMod(folder))
			return requiredBaseGameAvailable();

		return Paths.safeModIsDirectory(Paths.mods(folder));
		#else
		return false;
		#end
	}

	static function requiredBaseGameAvailable():Bool
	{
		#if MODS_ALLOWED
		return Paths.safeModIsDirectory(Paths.mods(BASE_GAME_MOD_FOLDER)) || Paths.safeModIsDirectory(BASE_GAME_LOCAL_FOLDER);
		#else
		return false;
		#end
	}

	static function normalizeModFolder(folder:String):String
	{
		if (folder == null)
			return '';
		var normalized:String = StringTools.trim(folder).replace('\\', '/');
		while (normalized.endsWith('/'))
			normalized = normalized.substr(0, normalized.length - 1);
		return normalized.toLowerCase();
	}

	static function packBool(folder:String, field:String, fallback:Bool):Bool
	{
		var value:Dynamic = getPackField(folder, field);
		if (value == null)
			return fallback;
		if (Std.isOfType(value, Bool))
			return cast value;

		var text:String = Std.string(value).trim().toLowerCase();
		return text == 'true' || text == '1' || text == 'yes' || text == 'on';
	}
}


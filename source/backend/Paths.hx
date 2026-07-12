package backend;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;
import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.system.System;
import openfl.geom.Rectangle;
import lime.utils.Assets;
import flash.media.Sound;
import haxe.Json;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
#if MODS_ALLOWED
import backend.Mods;
#end

@:access(openfl.display.BitmapData)
class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	/**
	 * Temporary frames cache that gets cleared between states.
	 */
	static var tempFramesCache:Map<String, FlxAtlasFrames> = [];

	static var animateAtlasExistenceCache:Map<String, Bool> = [];
	static var animateAtlasAnimationCache:Map<String, String> = [];
	static var animateAtlasSpriteJsonCache:Map<String, Array<String>> = [];
	static var animateAtlasPageKeysCache:Map<String, Array<String>> = [];

	/**
	 * Initialize Paths system
	 * Call this at game startup
	 */
	public static function init():Void
	{
		// Clear temp cache on state switch
		FlxG.signals.preStateSwitch.add(function()
		{
			clearTempFramesCache();
		});
	}

	/**
	 * Clear temporary frames cache
	 * Called automatically between state switches
	 */
	public static function clearTempFramesCache():Void
	{
		if (tempFramesCache == null)
			return;

		var count = 0;
		for (key => frames in tempFramesCache)
		{
			if (frames != null && frames.parent != null)
			{
				frames.parent.persist = false;
				frames.parent.destroyOnNoUse = true;
				count++;
			}
		}

		tempFramesCache.clear();
	}

	public static function hasAnimateAtlas(key:String):Bool
	{
		return cacheAnimateAtlasData(key);
	}

	public static function getAnimateAtlasPageKeys(key:String):Array<String>
	{
		if (!cacheAnimateAtlasData(key))
			return [];

		return animateAtlasPageKeysCache.get(key.trim()).copy();
	}

	static function getAnimateAtlasSpriteJsons(key:String):Array<String>
	{
		if (!cacheAnimateAtlasData(key))
			return [];

		return animateAtlasSpriteJsonCache.get(key.trim()).copy();
	}

	static function getAnimateAtlasAnimationJson(key:String):String
	{
		if (!cacheAnimateAtlasData(key))
			return null;

		return animateAtlasAnimationCache.get(key.trim());
	}

	static function cacheAnimateAtlasData(key:String):Bool
	{
		if (key == null)
			return false;

		key = key.trim();
		if (key.length == 0)
			return false;

		if (animateAtlasExistenceCache.exists(key))
			return animateAtlasExistenceCache.get(key);

		var animationJson:String = getTextFromFile('images/$key/Animation.json');
		if (animationJson == null)
		{
			animateAtlasExistenceCache.set(key, false);
			return false;
		}

		var spriteJsons:Array<String> = [];
		var pageKeys:Array<String> = [];
		for (i in 0...32)
		{
			var suffix:String = i == 0 ? '' : Std.string(i);
			var spriteJson:String = getTextFromFile('images/$key/spritemap$suffix.json');
			if (spriteJson == null)
			{
				if (pageKeys.length > 0)
					break;
				continue;
			}

			var pageKey:String = '$key/spritemap$suffix';
			if (!fileExists('images/$pageKey.png', IMAGE))
				continue;

			spriteJsons.push(spriteJson);
			pageKeys.push(pageKey);
		}

		var exists:Bool = pageKeys.length > 0;
		animateAtlasExistenceCache.set(key, exists);
		if (!exists)
			return false;

		animateAtlasAnimationCache.set(key, animationJson);
		animateAtlasSpriteJsonCache.set(key, spriteJsons);
		animateAtlasPageKeysCache.set(key, pageKeys);
		return true;
	}

	public static function excludeAsset(key:String)
	{
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = [
		'assets/shared/music/freakyMenu.$SOUND_EXT',
		'images/touchpad/*',
		'assets/shared/mobile/touchpad/*'
	];

	static function isAssetExcluded(key:String):Bool
	{
		if (key == null)
			return false;

		for (excluded in dumpExclusions)
		{
			if (excluded == null)
				continue;

			if (excluded.endsWith('*'))
			{
				var prefix = excluded.substr(0, excluded.length - 1);
				if (key.startsWith(prefix) || ('assets/' + key).startsWith(prefix))
					return true;
			}
			else if (key == excluded || ('assets/' + key) == excluded)
				return true;
		}

		return false;
	}

	// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) && !isAssetExcluded(key))
			{
				if (destroyGraphic(currentTrackedAssets.get(key)))
					currentTrackedAssets.remove(key); // and remove the key from local cache map
			}
		}
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = AssetCache.localTrackedAssets;

	@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
	public static function clearStoredMemory()
	{
		// clear anything not in the tracked assets list
		for (key in FlxG.bitmap._cache.keys())
		{
			if (!currentTrackedAssets.exists(key))
				destroyGraphic(FlxG.bitmap.get(key));
		}

		// clear all sounds that are cached
		for (key => asset in currentTrackedSounds)
		{
			if (!localTrackedAssets.contains(key) && !isAssetExcluded(key) && asset != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		AssetCache.resetLocalTracking();
		localTrackedAssets = AssetCache.localTrackedAssets;
		missingBitmapCache = AssetCache.missingBitmapCache;
		#if !html5 openfl.Assets.cache.clear("songs"); #end
	}

	public static function freeGraphicsFromMemory()
	{
		var protectedGfx:Array<FlxGraphic> = [];
		function checkForGraphics(spr:Dynamic)
		{
			try
			{
				var grp:Array<Dynamic> = Reflect.getProperty(spr, 'members');
				if (grp != null)
				{
					// trace('is actually a group');
					for (member in grp)
					{
						checkForGraphics(member);
					}
					return;
				}
			}

			// trace('check...');
			try
			{
				var gfx:FlxGraphic = Reflect.getProperty(spr, 'graphic');
				if (gfx != null)
				{
					protectedGfx.push(gfx);
					// trace('gfx added to the list successfully!');
				}
			}
			// catch(haxe.Exception) {}
		}

		for (member in FlxG.state.members)
			checkForGraphics(member);

		if (FlxG.state.subState != null)
			for (member in FlxG.state.subState.members)
				checkForGraphics(member);

		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!isAssetExcluded(key))
			{
				var graphic:FlxGraphic = currentTrackedAssets.get(key);
				if (!protectedGfx.contains(graphic))
				{
					if (destroyGraphic(graphic))
						currentTrackedAssets.remove(key); // and remove the key from local cache map
					// trace('deleted $key');
				}
			}
		}
	}

	static function destroyGraphic(graphic:FlxGraphic):Bool
		return AssetCache.destroyGraphic(graphic);

	static public var currentLevel:String;

	static public function setCurrentLevel(name:String)
		currentLevel = name.toLowerCase();

	public static function getPath(file:String, ?type:AssetType = TEXT, ?parentfolder:String, ?modsAllowed:Bool = true):String
		return AssetResolver.resolvePath(file, type, parentfolder, modsAllowed);

	inline static public function getFolderPath(file:String, folder = "shared")
		return 'assets/$folder/$file';

	inline public static function getSharedPath(file:String = '')
		return 'assets/shared/$file';

	inline static public function txt(key:String, ?folder:String)
		return getPath('data/$key.txt', TEXT, folder, true);

	inline static public function xml(key:String, ?folder:String)
		return getPath('data/$key.xml', TEXT, folder, true);

	inline static public function json(key:String, ?folder:String)
		return getPath('data/$key.json', TEXT, folder, true);

	inline static public function shaderFragment(key:String, ?folder:String)
		return getPath('shaders/$key.frag', TEXT, folder, true);

	inline static public function shaderVertex(key:String, ?folder:String)
		return getPath('shaders/$key.vert', TEXT, folder, true);

	inline static public function lua(key:String, ?folder:String)
		return getPath('$key.lua', TEXT, folder, true);

	inline static public function hx(key:String, ?folder:String)
		return getPath('scripts/states/$key/$key.hx', TEXT, folder, true);

	// Flat single-file path for CustomState (scripts/states/{name}.hx)
	inline static public function customState(key:String, ?folder:String)
		return getPath('scripts/states/$key.hx', TEXT, folder, true);

	inline static public function globalScript()
		return getPath('scripts/GlobalScript.hx', TEXT, null, true);

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if (FileSystem.exists(file))
			return file;
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	inline static public function sound(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('sounds/$key', modsAllowed);

	inline static public function music(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('music/$key', modsAllowed);

	inline static public function inst(song:String, ?modsAllowed:Bool = true):Sound
		return returnSound('${formatToSongPath(song)}/Inst', 'songs', modsAllowed);

	inline static public function voices(song:String, postfix:String = null, ?modsAllowed:Bool = true):Sound
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		if (postfix != null)
			songKey += '-' + postfix;
		// trace('songKey test: $songKey');
		return returnSound(songKey, 'songs', modsAllowed, false);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?modsAllowed:Bool = true)
		return sound(key + FlxG.random.int(min, max), modsAllowed);

	public static var currentTrackedAssets:Map<String, FlxGraphic> = AssetCache.currentTrackedAssets;
	static var missingBitmapCache:Map<String, Bool> = AssetCache.missingBitmapCache;

	static public function image(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxGraphic
	{
		key = Language.getFileTranslation('images/$key') + '.png';
		var bitmap:BitmapData = null;
		var resolvedFile:String = getPath(key, IMAGE, parentFolder, true);

		// Use the resolved path as cache key so assets with the same logical name
		// from different mods don't leak into each other.
		if (currentTrackedAssets.exists(resolvedFile))
		{
			AssetCache.remember(resolvedFile);
			localTrackedAssets = AssetCache.localTrackedAssets;
			return currentTrackedAssets.get(resolvedFile);
		}
		return cacheBitmap(key, parentFolder, bitmap, allowGPU);
	}

	public static function cacheBitmap(key:String, ?parentFolder:String = null, ?bitmap:BitmapData, ?allowGPU:Bool = true):FlxGraphic
	{
		var resolvedFile:String = null;
		if (bitmap == null)
		{
			resolvedFile = getPath(key, IMAGE, parentFolder, true);
			if (missingBitmapCache.exists(resolvedFile))
				return null;

			bitmap = AssetLoader.loadBitmap(resolvedFile);

			if (bitmap == null)
			{
				missingBitmapCache.set(resolvedFile, true);
				return null;
			}

			missingBitmapCache.remove(resolvedFile);
		}

		var cacheKey:String = (resolvedFile != null) ? resolvedFile : key;

		var graph:FlxGraphic = AssetCache.cacheBitmap(cacheKey, bitmap, allowGPU);
		currentTrackedAssets = AssetCache.currentTrackedAssets;
		localTrackedAssets = AssetCache.localTrackedAssets;
		return graph;
	}

	/** Removes UTF-8 BOM (U+FEFF) from a string if present, preventing JSON/XML parse errors. */
	inline static public function stripBOM(str:String):String
		return (str != null && str.charCodeAt(0) == 0xFEFF) ? str.substr(1) : str;

	inline static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		var path:String = getPath(key, TEXT, null, !ignoreMods);
		return AssetLoader.loadText(path);
	}

	inline static public function font(key:String)
	{
		var folderKey:String = Language.getFileTranslation('fonts/$key');
		#if MODS_ALLOWED
		var file:String = modFolders(folderKey);
		if (FileSystem.exists(file))
			return file;
		#end
		return 'assets/$folderKey';
	}

	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?parentFolder:String = null)
	{
		#if MODS_ALLOWED
		if (!ignoreMods)
		{
			var modKey:String = key;
			if (parentFolder == 'songs')
				modKey = 'songs/$key';

			for (mod in Mods.getGlobalMods())
				if (FileSystem.exists(mods('$mod/$modKey')))
					return true;
			#if linux
			else if (FileSystem.exists(findFile('$mod/$modKey')))
				return true;
			#end

			if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + modKey)) || FileSystem.exists(mods(modKey)))
				return true;
			#if linux
			else if (FileSystem.exists(findFile(modKey)))
				return true;
			#end
		}
		#end
		return AssetLoader.exists(getPath(key, type, parentFolder, false), type);
	}

	static public function getAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var useMod = false;
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);

		var myXml:Dynamic = getPath('images/$key.xml', TEXT, parentFolder, true);
		if (OpenFlAssets.exists(myXml) #if MODS_ALLOWED || (FileSystem.exists(myXml) && (useMod = true)) #end)
		{
			#if MODS_ALLOWED
			return FlxAtlasFrames.fromSparrow(imageLoaded, (useMod ? stripBOM(File.getContent(myXml)) : myXml));
			#else
			return FlxAtlasFrames.fromSparrow(imageLoaded, myXml);
			#end
		}
		else
		{
			var myJson:Dynamic = getPath('images/$key.json', TEXT, parentFolder, true);
			if (OpenFlAssets.exists(myJson) #if MODS_ALLOWED || (FileSystem.exists(myJson) && (useMod = true)) #end)
			{
				#if MODS_ALLOWED
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (useMod ? stripBOM(File.getContent(myJson)) : myJson));
				#else
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, myJson);
				#end
			}
		}
		return getPackerAtlas(key, parentFolder);
	}

	static public function getMultiAtlas(keys:Array<String>, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var parentFrames:FlxAtlasFrames = Paths.getAtlas(keys[0].trim());
		if (keys.length > 1)
		{
			var original:FlxAtlasFrames = parentFrames;
			parentFrames = new FlxAtlasFrames(parentFrames.parent);
			parentFrames.addAtlas(original, true);
			for (i in 1...keys.length)
			{
				var extraFrames:FlxAtlasFrames = Paths.getAtlas(keys[i].trim(), parentFolder, allowGPU);
				if (extraFrames != null)
					parentFrames.addAtlas(extraFrames, true);
			}
		}
		return parentFrames;
	}

	inline static public function getSparrowAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		if (key.contains('psychic'))
			trace(key, parentFolder, allowGPU);
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		var xmlExists:Bool = false;

		var xml:String = modsXml(key);
		if (FileSystem.exists(xml))
			xmlExists = true;

		return FlxAtlasFrames.fromSparrow(imageLoaded,
			(xmlExists ? stripBOM(File.getContent(xml)) : stripBOM(getTextFromFile(Language.getFileTranslation('images/$key') + '.xml', true))));
		#else
		return FlxAtlasFrames.fromSparrow(imageLoaded, stripBOM(getTextFromFile(Language.getFileTranslation('images/$key') + '.xml', true)));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		var txtExists:Bool = false;

		var txt:String = modsTxt(key);
		if (FileSystem.exists(txt))
			txtExists = true;

		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded,
			(txtExists ? stripBOM(File.getContent(txt)) : getPath(Language.getFileTranslation('images/$key') + '.txt', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.txt', TEXT, parentFolder));
		#end
	}

	inline static public function getAsepriteAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		var jsonExists:Bool = false;

		var json:String = modsImagesJson(key);
		if (FileSystem.exists(json))
			jsonExists = true;

		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded,
			(jsonExists ? stripBOM(File.getContent(json)) : getPath(Language.getFileTranslation('images/$key') + '.json', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.json', TEXT, parentFolder));
		#end
	}

	inline static public function formatToSongPath(path:String)
	{
		final invalidChars = ~/[~&;:<>#\s]/g;
		final hideChars = ~/[.,'"%?!]/g;

		return hideChars.replace(invalidChars.replace(path, '-'), '').trim().toLowerCase();
	}

	public static var currentTrackedSounds:Map<String, Sound> = AssetCache.currentTrackedSounds;

	public static function returnSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true)
	{
		var file:String = getPath(Language.getFileTranslation(key) + '.$SOUND_EXT', SOUND, path, modsAllowed);

		// trace('precaching sound: $file');
		if (!currentTrackedSounds.exists(file))
		{
			var sound:Sound = AssetLoader.loadSound(file);

			if (sound != null)
			{
				AssetCache.cacheSound(file, sound);
				currentTrackedSounds = AssetCache.currentTrackedSounds;
			}
			else if (beepOnNull)
			{
				trace('SOUND NOT FOUND: $key, PATH: $path');
				FlxG.log.error('SOUND NOT FOUND: $key, PATH: $path');
				return FlxAssets.getSound('flixel/sounds/beep');
			}
		}
		AssetCache.remember(file);
		localTrackedAssets = AssetCache.localTrackedAssets;
		return currentTrackedSounds.get(file);
	}

	#if MODS_ALLOWED
	static inline function normalizeModKey(key:String):String
		return key == null ? '' : key.replace('\\', '/');

	static function addUniqueModsRoot(list:Array<String>, path:String):Void
	{
		if (path == null || path.length == 0)
			return;

		var normalizedPath:String = path.replace('\\', '/');
		if (!normalizedPath.endsWith('/'))
			normalizedPath += '/';

		if (!list.contains(normalizedPath))
			list.push(normalizedPath);
	}

	public static function safeModPathExists(path:String):Bool
	{
		try
		{
			return FileSystem.exists(path);
		}
		catch (_:Dynamic)
		{
			return false;
		}
	}

	static function safeModIsDirectory(path:String):Bool
	{
		try
		{
			return FileSystem.isDirectory(path);
		}
		catch (_:Dynamic)
		{
			return false;
		}
	}

	public static function getModsRootDirectories():Array<String>
	{
		var roots:Array<String> = [];
		#if android
		if (StorageUtil.useExternalModsStorage())
		{
			for (modsRoot in StorageUtil.getPublicModsDirectoryCandidates())
				addUniqueModsRoot(roots, modsRoot);
		}
		else
			addUniqueModsRoot(roots, StorageUtil.getStorageDirectory() + 'mods/');
		#else
		addUniqueModsRoot(roots, Sys.getCwd() + 'mods/');
		#end
		return roots;
	}

	public static function getLegacyModsRootDirectories():Array<String>
	{
		var roots:Array<String> = getModsRootDirectories();
		#if MODS_ALLOWED
		var legacyRoots:Array<String> = [];
		#if android
		if (StorageUtil.useExternalModsStorage())
		{
			for (modsRoot in StorageUtil.getPublicModsDirectoryCandidates())
				addUniqueModsRoot(legacyRoots, modsRoot);
			addUniqueModsRoot(legacyRoots, StorageUtil.getStorageDirectory() + 'PsychEngine/mods/');
			addUniqueModsRoot(legacyRoots, StorageUtil.getStorageDirectory() + 'mods/');
		}
		else
			addUniqueModsRoot(legacyRoots, StorageUtil.getStorageDirectory() + 'PsychEngine/mods/');
		#else
		addUniqueModsRoot(legacyRoots, Sys.getCwd() + 'PsychEngine/mods/');
		addUniqueModsRoot(legacyRoots, Sys.getCwd() + 'mods/');
		#end
		for (root in legacyRoots)
			if (!roots.contains(root)) roots.push(root);
		#end
		return roots;
	}

	static function shouldSearchLegacyModsRoot(key:String):Bool
	{
		if (key == null || key.length == 0)
			return false;

		var firstSegment:String = normalizeModKey(key).split('/')[0];
		if (firstSegment == null || firstSegment.length == 0)
			return false;

		return !Mods.ignoreModFolders.contains(firstSegment.toLowerCase());
	}

	public static function getModsSearchRoots(?key:String):Array<String>
	{
		return ClientPrefs.data.legacyFileSystemAccess && shouldSearchLegacyModsRoot(key) ? getLegacyModsRootDirectories() : getModsRootDirectories();
	}

	public static function getPrimaryModsRoot():String
	{
		var roots:Array<String> = getModsRootDirectories();
		return
			roots.length > 0 ? roots[0] : (#if android (StorageUtil.useExternalModsStorage() ? StorageUtil.getPublicModsDirectory() : StorageUtil.getStorageDirectory()
			+ 'mods/')
			+ #else Sys.getCwd()
			+ #end '');
	}

	public static function getModRelativePath(path:String):String
	{
		if (path == null || path.length == 0)
			return null;

		var normalizedPath:String = path.replace('\\', '/');
		var roots:Array<String> = getModsRootDirectories();

		for (root in roots)
		{
			if (normalizedPath.startsWith(root))
				return normalizedPath.substr(root.length);
		}

		return null;
	}

	public static function getModFolderNameFromPath(path:String):String
	{
		var relativePath:String = getModRelativePath(path);
		if (relativePath == null || relativePath.length == 0)
			return null;

		var folderName:String = relativePath.split('/')[0];
		if (folderName == null || folderName.length == 0)
			return null;

		if (Mods.ignoreModFolders.contains(folderName.toLowerCase()))
			return null;

		return folderName;
	}

	public static function getModDirectory(modName:String):String
	{
		var normalizedModName:String = normalizeModKey(modName);
		if (normalizedModName.length == 0)
			return getPrimaryModsRoot();

		var resolvedPath:String = getPrimaryModsRoot() + normalizedModName;

		for (root in getModsSearchRoots(normalizedModName))
		{
			var candidate:String = root + normalizedModName;
			if (safeModPathExists(candidate) && safeModIsDirectory(candidate))
			{
				resolvedPath = candidate;
				break;
			}
		}

		return resolvedPath;
	}

	public static function mods(key:String = '')
	{
		var normalizedKey:String = normalizeModKey(key);
		if (normalizedKey.length == 0)
			return getPrimaryModsRoot();

		var resolvedPath:String = getPrimaryModsRoot() + normalizedKey;

		for (root in getModsSearchRoots(normalizedKey))
		{
			var candidate:String = root + normalizedKey;
			if (safeModPathExists(candidate))
			{
				resolvedPath = candidate;
				break;
			}
		}

		return resolvedPath;
	}

	inline static public function modsJson(key:String)
		return modFolders('data/' + key + '.json');

	inline static public function modsVideo(key:String)
		return modFolders('videos/' + key + '.' + VIDEO_EXT);

	inline static public function modsSounds(path:String, key:String)
		return modFolders(path + '/' + key + '.' + SOUND_EXT);

	inline static public function modsImages(key:String)
		return modFolders('images/' + key + '.png');

	inline static public function modsXml(key:String)
		return modFolders('images/' + key + '.xml');

	inline static public function modsTxt(key:String)
		return modFolders('images/' + key + '.txt');

	inline static public function modsImagesJson(key:String)
		return modFolders('images/' + key + '.json');

	/**
	 * Get path to an NDLL file in the mods folder
	 * @param key Name of the NDLL file (without extension)
	 * @return Full path to the NDLL file
	 */
	inline static public function modsNdll(key:String)
		return modFolders('ndlls/' + key + '.ndll');

	/**
	 * Get path to a DLL file in the mods folder
	 * @param key Name of the DLL file (without extension)
	 * @return Full path to the DLL file
	 */
	inline static public function modsDll(key:String)
		return modFolders('ndlls/' + key + '.dll');

	/**
	 * Get path to a native library (tries both .ndll and .dll)
	 * @param key Name of the library file (without extension)
	 * @return Full path to the library file, or null if not found
	 */
	static public function modsLibrary(key:String):String
	{
		// Try NDLL first
		var ndllPath:String = modsNdll(key);
		if (FileSystem.exists(ndllPath))
			return ndllPath;

		// Try DLL
		var dllPath:String = modsDll(key);
		if (FileSystem.exists(dllPath))
			return dllPath;

		// Try without ndlls folder (root of mod)
		var rootNdll:String = modFolders(key + '.ndll');
		if (FileSystem.exists(rootNdll))
			return rootNdll;

		var rootDll:String = modFolders(key + '.dll');
		if (FileSystem.exists(rootDll))
			return rootDll;

		return null;
	}

	/**
	 * List all NDLL files in the current mod's ndlls folder
	 * @return Array of NDLL filenames (without path or extension)
	 */
	static public function listModNdlls():Array<String>
	{
		var ndlls:Array<String> = [];

		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
		{
			var ndllsFolder:String = mods(Mods.currentModDirectory + '/ndlls');
			if (FileSystem.exists(ndllsFolder) && FileSystem.isDirectory(ndllsFolder))
			{
				for (file in FileSystem.readDirectory(ndllsFolder))
				{
					if (file.endsWith('.ndll') || file.endsWith('.dll'))
					{
						var name = file.substring(0, file.lastIndexOf('.'));
						ndlls.push(name);
					}
				}
			}
		}

		return ndlls;
	}

	/**
	 * Check if a native library exists in mods
	 * @param key Name of the library (without extension)
	 * @return True if the library exists
	 */
	static public function modsLibraryExists(key:String):Bool
	{
		return modsLibrary(key) != null;
	}

	static public function modFolders(key:String)
	{
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
		{
			var fileToCheck:String = mods(Mods.currentModDirectory + '/' + key);
			if (safeModPathExists(fileToCheck))
				return fileToCheck;
			#if linux
			else
			{
				var newPath:String = findFile(key);
				if (newPath != null)
					return newPath;
			}
			#end
		}

		for (mod in Mods.getGlobalMods())
		{
			var fileToCheck:String = mods(mod + '/' + key);
			if (safeModPathExists(fileToCheck))
				return fileToCheck;
			#if linux
			else
			{
				var newPath:String = findFile(key);
				if (newPath != null)
					return newPath;
			}
			#end
		}
		return mods(key);
	}

	#if linux
	static function findFile(key:String):String
	{
		var targetParts:Array<String> = key.replace('\\', '/').split('/');
		if (targetParts.length == 0)
			return null;

		var baseDir:String = targetParts.shift();
		var searchDirs:Array<String> = [mods(Mods.currentModDirectory + '/' + baseDir), mods(baseDir)];

		for (part in targetParts)
		{
			if (part == '')
				continue;

			var nextDir:String = findNodeInDirs(searchDirs, part);
			if (nextDir == null)
			{
				return null;
			}

			searchDirs = [nextDir];
		}

		return searchDirs[0];
	}

	static function findNodeInDirs(dirs:Array<String>, key:String):String
	{
		for (dir in dirs)
		{
			var node:String = findNode(dir, key);
			if (node != null)
			{
				return dir + '/' + node;
			}
		}
		return null;
	}

	static function findNode(dir:String, key:String):String
	{
		try
		{
			var allFiles:Array<String> = Paths.readDirectory(dir);
			var fileMap:Map<String, String> = new Map();

			for (file in allFiles)
			{
				fileMap.set(file.toLowerCase(), file);
			}

			return fileMap.get(key.toLowerCase());
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}
	#end
	#end
	#if flxanimate
	public static function loadAnimateAtlas(spr:FlxAnimate, folderOrImg:Dynamic, spriteJson:Dynamic = null, animationJson:Dynamic = null)
	{
		var changedAnimJson = false;
		var changedAtlasJson = false;
		var changedImage = false;

		if (spriteJson != null)
		{
			changedAtlasJson = true;
			spriteJson = File.getContent(spriteJson);
		}

		if (animationJson != null)
		{
			changedAnimJson = true;
			animationJson = File.getContent(animationJson);
		}

		// Folder/path-based auto-detection with full multi-page support
		if (Std.isOfType(folderOrImg, String))
		{
			var originalPath:String = folderOrImg;

			// Arrays to hold each spritemap page (JSON content + loaded graphic)
			var spritePages:Array<String> = [];
			var spriteImgs:Array<FlxGraphic> = [];

			if (!changedAtlasJson)
			{
				var cachedSpritePages:Array<String> = getAnimateAtlasSpriteJsons(originalPath);
				var cachedPageKeys:Array<String> = getAnimateAtlasPageKeys(originalPath);
				if (cachedSpritePages.length > 0 && cachedPageKeys.length == cachedSpritePages.length)
				{
					changedImage = true;
					changedAtlasJson = true;
					for (pageJson in cachedSpritePages)
						spritePages.push(pageJson);
					for (pageKey in cachedPageKeys)
						spriteImgs.push(image(pageKey));
				}
			}
			else
			{
				// spriteJson was given externally - just locate matching image(s)
				for (i in 0...10)
				{
					var st:String = (i == 0) ? '' : '$i';
					if (fileExists('images/$originalPath/spritemap$st.png', IMAGE))
					{
						changedImage = true;
						spriteImgs.push(image('$originalPath/spritemap$st'));
					}
					else if (changedImage)
						break;
				}
			}

			// Fallback to loading the folder as a plain image
			if (!changedImage)
			{
				changedImage = true;
				folderOrImg = image(originalPath);
			}

			if (!changedAnimJson)
			{
				animationJson = getAnimateAtlasAnimationJson(originalPath);
				if (animationJson == null)
					animationJson = getTextFromFile('images/$originalPath/Animation.json');
				changedAnimJson = (animationJson != null);
			}

			if (spritePages.length == 1)
			{
				folderOrImg = spriteImgs[0];
				spriteJson = spritePages[0];
			}
			else if (spriteImgs.length > 0)
				folderOrImg = spriteImgs[0];
		}

		spr.loadAtlasEx(folderOrImg, spriteJson, animationJson);
	}
	#end

	public static function readDirectory(directory:String):Array<String>
	{
		#if MODS_ALLOWED
		if (FileSystem.exists(directory))
			return FileSystem.readDirectory(directory);

		if (ClientPrefs.data.legacyFileSystemAccess)
			return [];

		#if android
		var prefix:String = directory.endsWith('/') ? directory : directory + '/';
		var filenames:Array<String> = [];
		for (asset in Assets.list())
		{
			if (!asset.startsWith(prefix))
				continue;
			var remainder:String = asset.substr(prefix.length);
			var name:String = remainder.split('/')[0];
			if (name.length > 0 && !filenames.contains(name))
				filenames.push(name);
		}
		return filenames;
		#else
		return [];
		#end
		#else
		var dirs:Array<String> = [];
		for (dir in Assets.list().filter(folder -> folder.startsWith(directory)))
		{
			@:privateAccess
			for (library in lime.utils.Assets.libraries.keys())
			{
				if (library != 'default' && Assets.exists('$library:$dir') && (!dirs.contains('$library:$dir') || !dirs.contains(dir)))
					dirs.push('$library:$dir');
				else if (Assets.exists(dir) && !dirs.contains(dir))
					dirs.push(dir);
			}
		}
		return dirs.map(dir -> dir.substr(dir.lastIndexOf("/") + 1));
		#end
	}
}


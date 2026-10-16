package backend;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;
import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
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
	inline public static var SOUND_EXT = "ogg";
	inline public static var VIDEO_EXT = "mp4";

	public static var uiBasePath:String = "";

	public static var uiSuffix:String = "";

	public static function getUIPath(assetName:String, useSuffix:Bool = true):String
	{
		var base:String = "images/";

		if (uiBasePath != null && uiBasePath.length > 0)
		{
			var normalizedPath = uiBasePath.replace('\\', '/');
			if (normalizedPath.startsWith("/"))
				normalizedPath = normalizedPath.substr(1);
			if (normalizedPath.endsWith("/"))
				normalizedPath = normalizedPath.substr(0, -1);

			base += normalizedPath + "/";
		}

		var normalizedAsset = assetName.replace('\\', '/');
		if (normalizedAsset.startsWith("/"))
			normalizedAsset = normalizedAsset.substr(1);

		base += normalizedAsset;

		if (useSuffix && uiSuffix != null && uiSuffix.length > 0)
		{
			var lastSlash:Int = base.lastIndexOf("/");
			var lastDot:Int = base.lastIndexOf(".");

			if (lastDot > lastSlash && lastDot != -1)
			{
				base = base.substr(0, lastDot) + uiSuffix + base.substr(lastDot);
			}
			else
			{
				base += uiSuffix;
			}
		}

		return base;
	}

	public static function setUIPath(uiName:String, isPixel:Bool = false):Void
	{
		if (uiName == null || uiName == "normal")
		{
			uiBasePath = "";
			uiSuffix = "";
			return;
		}

		uiName = uiName.replace('\\', '/');
		if (uiName.startsWith("/"))
			uiName = uiName.substr(1);
		if (uiName.endsWith("/"))
			uiName = uiName.substr(0, -1);

		if (uiName == "pixel")
			isPixel = true;
		if (uiName.endsWith("-pixel"))
		{
			uiName = uiName.substr(0, uiName.length - 6);
			isPixel = true;
		}

		var segments:Array<String> = uiName.split("/");
		var lastSegment:String = segments[segments.length - 1];

		if (lastSegment.toUpperCase().endsWith("UI"))
		{
			uiBasePath = uiName;
		}
		else
		{
			segments[segments.length - 1] = lastSegment + "UI";
			uiBasePath = segments.join("/");
		}

		uiSuffix = isPixel ? "-pixel" : "";
	}

	public static function resetUIPath():Void
	{
		uiBasePath = "";
		uiSuffix = "";
	}

	public static function getUIPrefix():String
	{
		if (uiBasePath == null || uiBasePath.length == 0)
			return "";
		return uiBasePath + "/";
	}

	static var tempFramesCache:Map<String, FlxAtlasFrames> = [];
	// Avoid resolving the same mod PNG/XML paths for every generated note.
	static var tempSparrowLookup:Map<String, FlxAtlasFrames> = [];
	static var retainTempFramesOnce:Bool = false;

	static var animateAtlasExistenceCache:Map<String, Bool> = [];
	static var animateAtlasAnimationCache:Map<String, String> = [];
	static var animateAtlasSpriteJsonCache:Map<String, Array<String>> = [];
	static var animateAtlasPageKeysCache:Map<String, Array<String>> = [];
	private static var initialized:Bool = false;

	public static function init():Void
	{
		if (initialized)
			return;
		initialized = true;

		FlxG.signals.preStateSwitch.add(function()
		{
			if (retainTempFramesOnce)
				retainTempFramesOnce = false;
			else
			{
				var releasedFrames:Int = clearTempFramesCache();
				if (releasedFrames > 0)
					MemoryManager.requestCollection('temporary atlas cache', releasedFrames);
			}
		});

		FlxG.signals.postStateSwitch.add(function()
		{
			// LoadingState may already have worker threads running. It performs the
			// pending collection itself after those workers have shut down.
			if (!Std.isOfType(FlxG.state, states.LoadingState))
				MemoryManager.runPendingCollection();
		});
	}

	/** Keeps loading-screen atlas parsing alive until the target state consumes it. */
	public static inline function retainTempFramesForNextState():Void
		retainTempFramesOnce = true;

	public static function clearTempFramesCache():Int
	{
		if (tempFramesCache == null)
			return 0;

		var released:Int = 0;
		for (_ in tempFramesCache.keys())
			released++;

		// The atlas does not own its parent graphic. AssetCache does, so changing
		// these flags here can destroy a bitmap that is still present in its map.
		tempFramesCache.clear();
		tempSparrowLookup.clear();
		return released;
	}

	public static function hasAnimateAtlas(key:String):Bool
	{
		return cacheAnimateAtlasData(key);
	}

	public static function getAnimateAtlasPageKeys(key:String):Array<String>
	{
		if (!cacheAnimateAtlasData(key))
			return [];

		return animateAtlasPageKeysCache.get(animateAtlasCacheKey(key)).copy();
	}

	static function getAnimateAtlasSpriteJsons(key:String):Array<String>
	{
		if (!cacheAnimateAtlasData(key))
			return [];

		return animateAtlasSpriteJsonCache.get(animateAtlasCacheKey(key)).copy();
	}

	static function getAnimateAtlasAnimationJson(key:String):String
	{
		if (!cacheAnimateAtlasData(key))
			return null;

		return animateAtlasAnimationCache.get(animateAtlasCacheKey(key));
	}

	static function animateAtlasCacheKey(key:String):String
	{
		var mod:String = '';
		#if MODS_ALLOWED
		mod = Mods.currentModDirectory == null ? '' : Mods.currentModDirectory;
		#end
		return mod + '::' + key.trim();
	}

	static function cacheAnimateAtlasData(key:String):Bool
	{
		if (key == null)
			return false;

		key = key.trim();
		if (key.length == 0)
			return false;

		var cacheKey:String = animateAtlasCacheKey(key);

		if (animateAtlasExistenceCache.exists(cacheKey))
			return animateAtlasExistenceCache.get(cacheKey);

		var animationJson:String = getTextFromFile('images/$key/Animation.json');
		if (animationJson == null)
		{
			animateAtlasExistenceCache.set(cacheKey, false);
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
		animateAtlasExistenceCache.set(cacheKey, exists);
		if (!exists)
			return false;

		animateAtlasAnimationCache.set(cacheKey, animationJson);
		animateAtlasSpriteJsonCache.set(cacheKey, spriteJsons);
		animateAtlasPageKeysCache.set(cacheKey, pageKeys);
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
	public static function clearUnusedMemory(runGarbageCollector:Bool = false)
	{
		var keysToRemove:Array<String> = [];

		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!AssetCache.isRemembered(key) && !isAssetExcluded(key))
			{
				if (destroyGraphic(currentTrackedAssets.get(key)))
					keysToRemove.push(key); // and remove the key from local cache map
			}
		}

		for (key in keysToRemove)
			currentTrackedAssets.remove(key);

		var releasedAssets:Int = keysToRemove.length + clearTempFramesCache();
		if (releasedAssets > 0 || runGarbageCollector)
			MemoryManager.requestCollection('Paths.clearUnusedMemory', releasedAssets);
		if (runGarbageCollector)
			MemoryManager.runPendingCollection(true);
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = AssetCache.localTrackedAssets;

	public static function rememberAsset(key:String):Void
	{
		AssetCache.remember(key);
		localTrackedAssets = AssetCache.localTrackedAssets;
	}

	public static function isAssetRemembered(key:String):Bool
	{
		return AssetCache.isRemembered(key);
	}

	public static function forgetAsset(key:String):Bool
	{
		var removed:Bool = AssetCache.forget(key);
		localTrackedAssets = AssetCache.localTrackedAssets;
		return removed;
	}

	@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
	public static function clearStoredMemory()
	{
		var graphicsToDestroy:Array<FlxGraphic> = [];

		// clear anything not in the tracked assets list
		for (key in FlxG.bitmap._cache.keys())
		{
			if (!currentTrackedAssets.exists(key))
			{
				var graphic:FlxGraphic = FlxG.bitmap.get(key);
				if (graphic != null)
					graphicsToDestroy.push(graphic);
			}
		}

		var destroyedGraphics:Int = 0;
		for (graphic in graphicsToDestroy)
			if (destroyGraphic(graphic))
				destroyedGraphics++;

		var soundsToRemove:Array<String> = [];

		// clear all sounds that are cached
		for (key => asset in currentTrackedSounds)
		{
			if (!AssetCache.isRemembered(key) && !isAssetExcluded(key) && asset != null)
			{
				Assets.cache.clear(key);
				soundsToRemove.push(key);
			}
		}

		for (key in soundsToRemove)
			currentTrackedSounds.remove(key);

		var releasedAssets:Int = destroyedGraphics + soundsToRemove.length;
		if (releasedAssets > 0)
			MemoryManager.requestCollection('Paths.clearStoredMemory', releasedAssets);

		// flags everything to be cleared out next unused memory clear
		AssetCache.resetLocalTracking();
		localTrackedAssets = AssetCache.localTrackedAssets;
		missingBitmapCache = AssetCache.missingBitmapCache;
		#if !html5 openfl.Assets.cache.clear("songs"); #end
	}

	public static function freeGraphicsFromMemory()
	{
		var protectedGfx:Array<FlxGraphic> = [];
		var keysToRemove:Array<String> = [];

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
						keysToRemove.push(key); // and remove the key from local cache map
					// trace('deleted $key');
				}
			}
		}

		for (key in keysToRemove)
			currentTrackedAssets.remove(key);

		if (keysToRemove.length > 0)
			MemoryManager.requestCollection('Paths.freeGraphicsFromMemory', keysToRemove.length);
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

	inline static public function globalScript()
		return getPath('scripts/GlobalScript.hx', TEXT, null, true);

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if (safeModPathExists(file))
			return file;
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	inline static public function sound(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('sounds/$key', modsAllowed);

	inline static public function music(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('music/$key', modsAllowed);

	inline static public function inst(song:String, ?modsAllowed:Bool = true):Sound
		return returnSound('${formatToSongPath(song)}/Inst', 'songs', modsAllowed, true, true);

	inline static public function voices(song:String, postfix:String = null, ?modsAllowed:Bool = true):Sound
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		if (postfix != null)
			songKey += '-' + postfix;
		// trace('songKey test: $songKey');
		return returnSound(songKey, 'songs', modsAllowed, false, true);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?modsAllowed:Bool = true)
		return sound(key + FlxG.random.int(min, max), modsAllowed);

	public static var currentTrackedAssets:Map<String, FlxGraphic> = AssetCache.currentTrackedAssets;
	static var missingBitmapCache:Map<String, Bool> = AssetCache.missingBitmapCache;

	static public function image(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxGraphic
	{
		key = key.replace('\\', '/');
		key = key.startsWith('images/') ? key : 'images/$key';
		key = Language.getFileTranslation(key);
		if (!key.endsWith('.png'))
			key += '.png';
		var bitmap:BitmapData = null;
		var resolvedFile:String = getPath(key, IMAGE, parentFolder, true);

		if (!allowGPU)
		{
			var cpuCacheKey:String = resolvedFile + '#cpu';
			if (currentTrackedAssets.exists(cpuCacheKey))
			{
				AssetCache.remember(cpuCacheKey);
				localTrackedAssets = AssetCache.localTrackedAssets;
				return currentTrackedAssets.get(cpuCacheKey);
			}

			if (currentTrackedAssets.exists(resolvedFile))
			{
				var cached:FlxGraphic = currentTrackedAssets.get(resolvedFile);
				if (cached != null && cached.bitmap != null && cached.bitmap.readable)
				{
					AssetCache.remember(resolvedFile);
					localTrackedAssets = AssetCache.localTrackedAssets;
					return cached;
				}
			}

			if (missingBitmapCache.exists(resolvedFile))
				return null;

			bitmap = AssetLoader.loadBitmap(resolvedFile);
			if (bitmap == null)
			{
				missingBitmapCache.set(resolvedFile, true);
				return null;
			}

			missingBitmapCache.remove(resolvedFile);
			var cpuGraph:FlxGraphic = AssetCache.cacheBitmap(cpuCacheKey, bitmap, false);
			currentTrackedAssets = AssetCache.currentTrackedAssets;
			localTrackedAssets = AssetCache.localTrackedAssets;
			return cpuGraph;
		}

		// Use the resolved path as cache key so assets with the same logical name
		// from different mods don't leak into each other.
		if (currentTrackedAssets.exists(resolvedFile))
		{
			var cached:FlxGraphic = currentTrackedAssets.get(resolvedFile);
			if (cached != null && cached.bitmap != null)
			{
				AssetCache.remember(resolvedFile);
				localTrackedAssets = AssetCache.localTrackedAssets;
				return cached;
			}
			currentTrackedAssets.remove(resolvedFile);
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
		if (safeModPathExists(file))
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
				if (safeModPathExists(mods('$mod/$modKey')))
					return true;
			#if linux
			else if (safeModPathExists(findFile('$mod/$modKey')))
				return true;
			#end

			if (safeModPathExists(mods(Mods.currentModDirectory + '/' + modKey)) || safeModPathExists(mods(modKey)))
				return true;
			#if linux
			else if (safeModPathExists(findFile(modKey)))
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
		if (OpenFlAssets.exists(myXml) #if MODS_ALLOWED || (safeModPathExists(myXml) && (useMod = true)) #end)
		{
			#if MODS_ALLOWED
			return FlxAtlasFrames.fromSparrow(imageLoaded, (useMod ? stripBOM(safeFileContent(myXml)) : myXml));
			#else
			return FlxAtlasFrames.fromSparrow(imageLoaded, myXml);
			#end
		}
		else
		{
			var myJson:Dynamic = getPath('images/$key.json', TEXT, parentFolder, true);
			if (OpenFlAssets.exists(myJson) #if MODS_ALLOWED || (safeModPathExists(myJson) && (useMod = true)) #end)
			{
				#if MODS_ALLOWED
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (useMod ? stripBOM(safeFileContent(myJson)) : myJson));
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

	static function sparrowLookupKey(key:String, parentFolder:String, allowGPU:Bool):String
	{
		var mod:String = '';
		#if MODS_ALLOWED
		mod = Mods.currentModDirectory == null ? '' : Mods.currentModDirectory;
		#end
		return '$mod|$currentLevel|$parentFolder|$allowGPU|$key';
	}

	static public function getSparrowAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var logicalKey:String = sparrowLookupKey(key, parentFolder, allowGPU);
		var logicalCached:FlxAtlasFrames = tempSparrowLookup.get(logicalKey);
		if (logicalCached != null)
			return logicalCached;

		if (key.contains('psychic'))
			trace(key, parentFolder, allowGPU);
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		var translatedXml:String = Language.getFileTranslation('images/$key') + '.xml';
		var xmlPath:String = getPath(translatedXml, TEXT, parentFolder, true);
		#if MODS_ALLOWED
		var xml:String = modsXml(key);
		if (safeModPathExists(xml))
			xmlPath = xml;
		#end

		var imagePath:String = getPath(Language.getFileTranslation('images/$key') + '.png', IMAGE, parentFolder, true);
		var cacheKey:String = '$imagePath|$xmlPath|$allowGPU';
		var cached:FlxAtlasFrames = tempFramesCache.get(cacheKey);
		if (cached != null)
		{
			tempSparrowLookup.set(logicalKey, cached);
			return cached;
		}

		#if MODS_ALLOWED
		var xmlData:String = xmlPath == xml ? stripBOM(safeFileContent(xml)) : stripBOM(getTextFromFile(translatedXml, true));
		#else
		var xmlData:String = stripBOM(getTextFromFile(translatedXml, true));
		#end
		var frames:FlxAtlasFrames = FlxAtlasFrames.fromSparrow(imageLoaded, xmlData);
		tempFramesCache.set(cacheKey, frames);
		tempSparrowLookup.set(logicalKey, frames);
		return frames;
	}

	inline static public function getPackerAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		var txtExists:Bool = false;

		var txt:String = modsTxt(key);
		if (safeModPathExists(txt))
			txtExists = true;

		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded,
			(txtExists ? stripBOM(safeFileContent(txt)) : getPath(Language.getFileTranslation('images/$key') + '.txt', TEXT, parentFolder)));
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
		if (safeModPathExists(json))
			jsonExists = true;

		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded,
			(jsonExists ? stripBOM(safeFileContent(json)) : getPath(Language.getFileTranslation('images/$key') + '.json', TEXT, parentFolder)));
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

	public static function returnSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true, ?stream:Bool = false)
	{
		var file:String = getPath(Language.getFileTranslation(key) + '.$SOUND_EXT', SOUND, path, modsAllowed);
		var cacheKey:String = stream ? file + '#stream' : file;

		// trace('precaching sound: $file');
		if (!currentTrackedSounds.exists(cacheKey))
		{
			var sound:Sound = stream ? AssetLoader.loadStreamedSound(file) : AssetLoader.loadSound(file);

			if (sound != null)
			{
				AssetCache.cacheSound(cacheKey, sound);
				currentTrackedSounds = AssetCache.currentTrackedSounds;
			}
			else if (beepOnNull)
			{
				trace('SOUND NOT FOUND: $key, PATH: $path');
				FlxG.log.error('SOUND NOT FOUND: $key, PATH: $path');
				return FlxAssets.getSound('flixel/sounds/beep');
			}
		}
		AssetCache.remember(cacheKey);
		localTrackedAssets = AssetCache.localTrackedAssets;
		return currentTrackedSounds.get(cacheKey);
	}

	#if MODS_ALLOWED
	static inline var BASE_GAME_MOD_FOLDER:String = 'Friday Night Funkin';
	static inline var BASE_GAME_LOCAL_FOLDER:String = 'base_game';

	static inline function normalizeModKey(key:String):String
		return key == null ? '' : key.replace('\\', '/');

	static function baseGameLocalPath(normalizedKey:String):String
	{
		if (normalizedKey == null || normalizedKey.length == 0)
			return null;

		if (normalizedKey == BASE_GAME_MOD_FOLDER)
			return BASE_GAME_LOCAL_FOLDER;

		var prefix:String = BASE_GAME_MOD_FOLDER + '/';
		if (normalizedKey.startsWith(prefix))
			return BASE_GAME_LOCAL_FOLDER + '/' + normalizedKey.substr(prefix.length);

		return null;
	}

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

	static var cachedModsRoots:Array<String> = null;
	static var cachedModsRootsSignature:String = null;

	public static function safeModPathExists(path:String):Bool
	{
		if (path == null || path.length == 0)
			return false;

		try
		{
			return FileSystem.exists(path);
		}
		catch (_:Dynamic)
		{
			return false;
		}
	}

	public static function safeModIsDirectory(path:String):Bool
	{
		if (path == null || path.length == 0)
			return false;

		try
		{
			return FileSystem.isDirectory(path);
		}
		catch (_:Dynamic)
		{
			return false;
		}
	}

	public static function safeFileContent(path:String):String
	{
		if (path == null || path.length == 0)
			return null;

		try
		{
			if (FileSystem.exists(path))
				return File.getContent(path);
		}
		catch (_:Dynamic)
		{
		}
		return null;
	}

	public static function safeReadDirectory(path:String):Array<String>
	{
		if (path == null || path.length == 0)
			return [];

		try
		{
			if (FileSystem.exists(path) && FileSystem.isDirectory(path))
				return FileSystem.readDirectory(path);
		}
		catch (_:Dynamic)
		{
		}
		return [];
	}

	public static function getModsRootDirectories():Array<String>
	{
		var signature:String = #if android ClientPrefs.data.storageType #else Sys.getCwd() #end;
		if (cachedModsRoots != null && cachedModsRootsSignature == signature)
			return cachedModsRoots.copy();

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
		cachedModsRoots = roots;
		cachedModsRootsSignature = signature;
		return roots.copy();
	}

	public static function getModsSearchRoots(?key:String):Array<String>
	{
		return getModsRootDirectories();
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

		var normalizedPath:String = path.trim().replace('\\', '/');
		var roots:Array<String> = getModsRootDirectories();

		for (root in roots)
		{
			var normalizedRoot:String = root.replace('\\', '/');
			if (!normalizedRoot.endsWith('/'))
				normalizedRoot += '/';

			#if windows
			if (normalizedPath.toLowerCase().startsWith(normalizedRoot.toLowerCase()))
			#else
			if (normalizedPath.startsWith(normalizedRoot))
			#end
				return normalizedPath.substr(normalizedRoot.length);
		}

		// Script paths may be stored relative to the executable instead of as
		// absolute paths. Accept both "mods/foo/..." and "./mods/foo/...".
		while (normalizedPath.startsWith('./'))
			normalizedPath = normalizedPath.substr(2);
		#if windows
		var comparablePath:String = normalizedPath.toLowerCase();
		#else
		var comparablePath:String = normalizedPath;
		#end
		var marker:String = 'mods/';
		var markerIndex:Int = comparablePath.startsWith(marker) ? 0 : comparablePath.lastIndexOf('/' + marker);
		if (markerIndex >= 0)
			return normalizedPath.substr(markerIndex + (markerIndex == 0 ? marker.length : marker.length + 1));

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

		var baseGameFallback:String = baseGameLocalPath(normalizedModName);
		if (baseGameFallback != null && safeModPathExists(baseGameFallback) && safeModIsDirectory(baseGameFallback))
			return baseGameFallback;

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

		var baseGameFallback:String = baseGameLocalPath(normalizedKey);
		if (baseGameFallback != null && safeModPathExists(baseGameFallback))
			return baseGameFallback;

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

	inline static public function modsNdll(key:String)
		return modFolders('ndlls/' + key + '.ndll');

	inline static public function modsDll(key:String)
		return modFolders('ndlls/' + key + '.dll');

	static public function modsLibrary(key:String):String
	{
		var ndllPath:String = modsNdll(key);
		if (safeModPathExists(ndllPath))
			return ndllPath;

		var dllPath:String = modsDll(key);
		if (safeModPathExists(dllPath))
			return dllPath;

		var rootNdll:String = modFolders(key + '.ndll');
		if (safeModPathExists(rootNdll))
			return rootNdll;

		var rootDll:String = modFolders(key + '.dll');
		if (safeModPathExists(rootDll))
			return rootDll;

		return null;
	}

	static public function listModNdlls():Array<String>
	{
		var ndlls:Array<String> = [];

		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
		{
			var ndllsFolder:String = mods(Mods.currentModDirectory + '/ndlls');
			if (safeModPathExists(ndllsFolder) && safeModIsDirectory(ndllsFolder))
			{
				for (file in safeReadDirectory(ndllsFolder))
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
	static function loadAnimateAtlasFromKeys(spr:FlxAnimate, keys:Array<String>):Void
	{
		var cleanKeys:Array<String> = [];
		for (key in keys)
		{
			if (key == null)
				continue;

			key = key.trim();
			if (key.length > 0 && !cleanKeys.contains(key))
				cleanKeys.push(key);
		}

		if (cleanKeys.length < 1)
			return;

		var frames:flxanimate.frames.FlxAnimateFrames = new flxanimate.frames.FlxAnimateFrames();
		var animationJsons:Array<String> = [];

		for (key in cleanKeys)
		{
			var spritePages:Array<String> = getAnimateAtlasSpriteJsons(key);
			var pageKeys:Array<String> = getAnimateAtlasPageKeys(key);
			if (spritePages.length < 1 || pageKeys.length != spritePages.length)
				throw 'Missing Animate atlas spritemap data for "$key"';

			for (i in 0...spritePages.length)
				frames.addAtlas(parseAnimateSpritemap(spritePages[i], image(pageKeys[i])), true);

			var animationJson:String = getAnimateAtlasAnimationJson(key);
			if (animationJson != null)
				animationJsons.push(animationJson);
		}

		if (animationJsons.length < 1)
			throw 'Missing Animate atlas Animation.json for "${cleanKeys[0]}"';

		spr.loadSeparateAtlas(animationJsons[0], frames);
		if (Std.isOfType(spr, flxanimate.PsychFlxAnimate))
		{
			var atlas:flxanimate.PsychFlxAnimate = cast spr;
			for (i in 1...animationJsons.length)
				atlas.addAtlasLibrary(animationJsons[i]);
		}
	}

	static function parseAnimateSpritemap(spriteJson:String, graphic:FlxGraphic):FlxAtlasFrames
	{
		var data:Dynamic = Json.parse(stripBOM(spriteJson));
		var frames:FlxAtlasFrames = new FlxAtlasFrames(graphic);
		var sprites:Array<Dynamic> = cast data.ATLAS.SPRITES;

		for (sprite in sprites)
		{
			var limb:Dynamic = sprite.SPRITE;
			if (limb == null)
				continue;

			// Use flxanimate's canonical parser for Adobe Animate spritemaps.
			// It handles rotated and zero-sized atlas entries consistently with
			// the library's regular fromSpriteMap() path.
			var rotated:Bool = limb.rotated == true;
			var rect:FlxRect = FlxRect.get(Std.int(limb.x), Std.int(limb.y), Std.int(limb.w), Std.int(limb.h));
			if (rotated)
				rect.setSize(rect.height, rect.width);

			flxanimate.frames.FlxAnimateFrames.sliceFrame(
				Std.string(limb.name),
				rotated,
				rect,
				null,
				null,
				frames
			);
		}

		return frames;
	}

	public static function loadAnimateAtlas(spr:FlxAnimate, folderOrImg:Dynamic, spriteJson:Dynamic = null, animationJson:Dynamic = null)
	{
		var changedAnimJson = false;
		var changedAtlasJson = false;
		var changedImage = false;

		if (Std.isOfType(folderOrImg, Array))
		{
			loadAnimateAtlasFromKeys(spr, cast folderOrImg);
			return;
		}

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

			if (spritePages.length > 0)
			{
				var frames:flxanimate.frames.FlxAnimateFrames = new flxanimate.frames.FlxAnimateFrames();
				for (i in 0...spritePages.length)
					frames.addAtlas(parseAnimateSpritemap(spritePages[i], spriteImgs[i]), true);

				spr.loadSeparateAtlas(animationJson, frames);
				return;
			}
		}

		spr.loadAtlasEx(folderOrImg, spriteJson, animationJson);
	}
	#end

	public static function readDirectory(directory:String):Array<String>
	{
		#if MODS_ALLOWED
		var files:Array<String> = safeReadDirectory(directory);
		if (files.length > 0)
			return files;

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

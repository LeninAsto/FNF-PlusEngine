package funkin;

import flixel.graphics.frames.FlxAtlasFrames;
import animate.FlxAnimateFrames;
import funkin.graphics.FunkinSprite.AtlasSpriteSettings;
import openfl.utils.AssetType;
import funkin.util.macro.ConsoleMacro;
import haxe.io.Path;

/**
 * A core class which handles determining asset paths.
 */
@:nullSafety
class Paths implements ConsoleClass
{
  static var currentLevel:Null<String> = null;

  public static function setCurrentLevel(name:Null<String>):Void
  {
    if (name == null)
    {
      currentLevel = null;
    }
    else
    {
      currentLevel = name.toLowerCase();
    }
  }

  public static function stripLibrary(path:String):String
  {
    var parts:Array<String> = path.split(':');
    if (parts.length < 2) return path;
    return parts[1];
  }

  public static function getLibrary(path:String):String
  {
    var parts:Array<String> = path.split(':');
    if (parts.length < 2) return 'preload';
    return parts[0];
  }

  static function getPath(file:String, type:AssetType, library:Null<String>):String
  {
    if (library != null) return getLibraryPath(file, library);

    if (currentLevel != null)
    {
      var levelPath:String = getLibraryPath(file, currentLevel);
      if (Assets.exists(levelPath, type)) return Assets.resolvePath(levelPath, type);
    }

    var levelPath:String = getLibraryPath(file, 'shared');
    if (Assets.exists(levelPath, type)) return Assets.resolvePath(levelPath, type);

    var preloadPath:String = getPreloadPath(file);
    if (Assets.exists(preloadPath, type)) return Assets.resolvePath(preloadPath, type);
    var namespacedPreloadPath:String = getNamespacedPreloadPath(file);
    if (Assets.exists(namespacedPreloadPath, type)) return namespacedPreloadPath;
    return getPreloadPath(file);
  }

  public static function getLibraryPath(file:String, library = 'preload'):String
  {
    if (library == 'preload' || library == 'default')
    {
      var preloadPath:String = getPreloadPath(file);
      if (Assets.exists(preloadPath)) return Assets.resolvePath(preloadPath);

      var namespacedPreloadPath:String = getNamespacedPreloadPath(file);
      if (Assets.exists(namespacedPreloadPath)) return namespacedPreloadPath;

      return preloadPath;
    }

    var libraryPath:String = getLibraryPathForce(file, library);
    if (Assets.exists(libraryPath)) return Assets.resolvePath(libraryPath);

    var flatPath:String = getFlatLibraryPathForce(file, library);
    if (Assets.exists(flatPath)) return Assets.resolvePath(flatPath);

    var namespacedLibraryPath:String = getNamespacedLibraryPathForce(file, library);
    if (Assets.exists(namespacedLibraryPath)) return namespacedLibraryPath;

    var namespacedFlatPath:String = getNamespacedFlatLibraryPathForce(file, library);
    if (Assets.exists(namespacedFlatPath)) return namespacedFlatPath;

    return Assets.hasLibrary(library) ? libraryPath : flatPath;
  }

  static inline function getLibraryPathForce(file:String, library:String):String
  {
    return '$library:assets/$library/$file';
  }

  static inline function getFlatLibraryPathForce(file:String, library:String):String
  {
    return 'assets/$library/$file';
  }

  static inline function getNamespacedLibraryPathForce(file:String, library:String):String
  {
    return '$library:assets/funkin/$library/$file';
  }

  static inline function getNamespacedFlatLibraryPathForce(file:String, library:String):String
  {
    return 'assets/funkin/$library/$file';
  }

  static inline function getPreloadPath(file:String):String
  {
    return 'assets/$file';
  }

  static inline function getNamespacedPreloadPath(file:String):String
  {
    return 'assets/funkin/$file';
  }

  public static function file(file:String, type:AssetType = TEXT, ?library:String):String
  {
    return getPath(file, type, library);
  }

  public static function animateAtlas(path:String, ?library:String):String
  {
    return getLibraryPath('images/$path', library);
  }

  public static function txt(key:String, ?library:String):String
  {
    return getPath('data/$key.txt', TEXT, library);
  }

  public static function frag(key:String, ?library:String):String
  {
    return getPath('shaders/$key.frag', TEXT, library);
  }

  public static function vert(key:String, ?library:String):String
  {
    return getPath('shaders/$key.vert', TEXT, library);
  }

  public static function xml(key:String, ?library:String):String
  {
    return getPath('data/$key.xml', TEXT, library);
  }

  public static function json(key:String, ?library:String):String
  {
    return getPath('data/$key.json', TEXT, library);
  }

  public static function srt(key:String, ?library:String, ?directory:String = "data/"):String
  {
    return getPath('$directory$key.srt', TEXT, library);
  }

  public static function sound(key:String, ?library:String):String
  {
    return getPath('sounds/$key.${Constants.EXT_SOUND}', SOUND, library);
  }

  public static function soundRandom(key:String, min:Int, max:Int, ?library:String):String
  {
    return sound(key + FlxG.random.int(min, max), library);
  }

  public static function music(key:String, ?library:String):String
  {
    return getPath('music/$key.${Constants.EXT_SOUND}', MUSIC, library);
  }

  public static function videos(key:String, ?library:String):String
  {
    final path:Path = new Path(key);

    if (path.ext != null)
    {
      return getPath('videos/${path.file}.${path.ext}', BINARY, library ?? 'videos');
    }

    return getPath('videos/$key.${Constants.EXT_VIDEO}', BINARY, library ?? 'videos');
  }

  public static function voices(song:String, ?suffix:String = ''):String
  {
    if (suffix == null) suffix = ''; // no suffix, for a sorta backwards compatibility with older-ish voice files

    var path:String = 'songs:assets/songs/${song.toLowerCase()}/Voices$suffix.${Constants.EXT_SOUND}';
    var flatPath:String = 'assets/songs/${song.toLowerCase()}/Voices$suffix.${Constants.EXT_SOUND}';
    var namespacedPath:String = 'songs:assets/funkin/songs/${song.toLowerCase()}/Voices$suffix.${Constants.EXT_SOUND}';
    var namespacedFlatPath:String = 'assets/funkin/songs/${song.toLowerCase()}/Voices$suffix.${Constants.EXT_SOUND}';
    if (Assets.hasLibrary('songs') && Assets.exists(path, SOUND)) return path;
    if (Assets.exists(flatPath, SOUND)) return flatPath;
    if (Assets.exists(namespacedPath, SOUND)) return namespacedPath;
    if (Assets.exists(namespacedFlatPath, SOUND)) return namespacedFlatPath;
    return Assets.hasLibrary('songs') ? path : flatPath;
  }

  /**
   * Gets the path to an `Inst.mp3/ogg` song instrumental from songs:assets/songs/`song`/
   * @param song name of the song to get instrumental for
   * @param suffix any suffix to add to end of song name, used for `-erect` variants usually
   * @param withExtension if it should return with the audio file extension `.mp3` or `.ogg`.
   * @return String
   */
  public static function inst(song:String, ?suffix:String = '', withExtension:Bool = true):String
  {
    var ext:String = withExtension ? '.${Constants.EXT_SOUND}' : '';
    var path:String = 'songs:assets/songs/${song.toLowerCase()}/Inst$suffix$ext';
    var flatPath:String = 'assets/songs/${song.toLowerCase()}/Inst$suffix$ext';
    var namespacedPath:String = 'songs:assets/funkin/songs/${song.toLowerCase()}/Inst$suffix$ext';
    var namespacedFlatPath:String = 'assets/funkin/songs/${song.toLowerCase()}/Inst$suffix$ext';
    if (Assets.hasLibrary('songs') && Assets.exists(path, SOUND)) return path;
    if (Assets.exists(flatPath, SOUND)) return flatPath;
    if (Assets.exists(namespacedPath, SOUND)) return namespacedPath;
    if (Assets.exists(namespacedFlatPath, SOUND)) return namespacedFlatPath;
    return Assets.hasLibrary('songs') ? path : flatPath;
  }

  public static function image(key:String, ?library:String):String
  {
    return getPath('images/$key.png', IMAGE, library);
  }

  public static function font(key:String):String
  {
    var path:String = 'assets/fonts/$key';
    if (Assets.exists(path)) return Assets.resolvePath(path);

    var namespacedPath:String = 'assets/funkin/fonts/$key';
    if (Assets.exists(namespacedPath)) return namespacedPath;

    return path;
  }

  public static function ui(key:String, ?library:String):String
  {
    return xml('ui/$key', library);
  }

  public static function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames
  {
    return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
  }

  public static function getAnimateAtlas(key:String, ?library:String, settings:AtlasSpriteSettings):FlxAnimateFrames
  {
    var validatedSettings:AtlasSpriteSettings = {
      swfMode: settings?.swfMode ?? false,
      cacheOnLoad: settings?.cacheOnLoad ?? false,
      filterQuality: settings?.filterQuality ?? MEDIUM,
      spritemaps: settings?.spritemaps ?? null,
      metadataJson: settings?.metadataJson ?? null,
      cacheKey: settings?.cacheKey ?? null,
      uniqueInCache: settings?.uniqueInCache ?? false,
      onSymbolCreate: settings?.onSymbolCreate ?? null,
      applyStageMatrix: settings?.applyStageMatrix ?? false,
      useRenderTexture: settings?.useRenderTexture ?? false
    };

    var lastError:Dynamic = null;
    var triedCandidates:Array<String> = [];

    for (candidate in getAnimateAtlasCandidates(key, library))
    {
      var graphicKey:Null<String> = resolveAnimateAtlasPath(candidate);
      if (graphicKey == null) continue;
      if (triedCandidates.contains(graphicKey)) continue;
      triedCandidates.push(graphicKey);

      try
      {
        var frames:FlxAnimateFrames = loadAnimateAtlas(graphicKey, validatedSettings);
        if (frames != null) return frames;
      }
      catch (e:Dynamic)
      {
        lastError = e;
        trace('Failed to load AnimateAtlas candidate $graphicKey: $e');
      }
    }

    if (lastError != null) throw 'Failed to load AnimateAtlas "$key": $lastError';
    throw 'No Animation.json file exists at the specified path (${getAnimateAtlasCandidates(key, library).join(", ")})';
  }

  static function getAnimateAtlasCandidates(key:String, ?library:String):Array<String>
  {
    var candidates:Array<String> = [];
    var file:String = 'images/$key';

    function add(path:String):Void
    {
      if (path != null && !candidates.contains(path)) candidates.push(path);
    }

    if (library != null && library.length > 0)
    {
      add(getLibraryPath(file, library));
      add(getLibraryPathForce(file, library));
      add(getFlatLibraryPathForce(file, library));
      add(getNamespacedLibraryPathForce(file, library));
      add(getNamespacedFlatLibraryPathForce(file, library));
    }
    else
    {
      if (currentLevel != null) add(getLibraryPath(file, currentLevel));
      add(getLibraryPath(file, 'shared'));
      add(getPreloadPath(file));
      add(getNamespacedPreloadPath(file));
    }

    return candidates;
  }

  static function resolveAnimateAtlasPath(path:String):Null<String>
  {
    var animationPath:String = Assets.resolvePath('$path/Animation.json', TEXT);
    if (!Assets.exists(animationPath, TEXT)) return null;
    return animationPath.substr(0, animationPath.length - '/Animation.json'.length);
  }

  static function loadAnimateAtlas(graphicKey:String, settings:AtlasSpriteSettings):FlxAnimateFrames
  {
    var cacheKey:String = settings.cacheKey ?? graphicKey;
    var flxAnimateSettings = {
      swfMode: settings.swfMode,
      cacheOnLoad: settings.cacheOnLoad,
      filterQuality: settings.filterQuality,
      onSymbolCreate: settings.onSymbolCreate
    };

    if (settings.spritemaps != null || settings.metadataJson != null)
    {
      return FlxAnimateFrames.fromAnimate(graphicKey, settings.spritemaps, settings.metadataJson, cacheKey, settings.uniqueInCache, flxAnimateSettings);
    }

    var spritemaps:Array<Dynamic> = collectAnimateSpritemaps(graphicKey);
    if (spritemaps.length > 0)
    {
      var animationJson:String = stripBOM(Assets.getText('$graphicKey/Animation.json'));
      var metadataJson:Null<String> = Assets.exists('$graphicKey/metadata.json', TEXT) ? stripBOM(Assets.getText('$graphicKey/metadata.json')) : null;
      var frames:FlxAnimateFrames = FlxAnimateFrames.fromAnimate(animationJson, cast spritemaps, metadataJson, cacheKey, settings.uniqueInCache,
        flxAnimateSettings);
      if (frames != null) return frames;
    }

    return FlxAnimateFrames.fromAnimate(graphicKey, null, null, cacheKey, settings.uniqueInCache, flxAnimateSettings);
  }

  static function collectAnimateSpritemaps(graphicKey:String):Array<Dynamic>
  {
    var spritemaps:Array<Dynamic> = [];

    addSpritemap(spritemaps, graphicKey, '');
    for (i in 1...100)
    {
      addSpritemap(spritemaps, graphicKey, Std.string(i));
    }

    return spritemaps;
  }

  static function addSpritemap(spritemaps:Array<Dynamic>, graphicKey:String, id:String):Void
  {
    var base:String = 'spritemap$id';
    var jsonPath:Null<String> = resolveAnimateFile(graphicKey, '$base.json', TEXT);
    if (jsonPath == null) return;

    var imagePath:Null<String> = null;
    for (extension in ['png', 'jpg', 'jpeg'])
    {
      imagePath = resolveAnimateFile(graphicKey, '$base.$extension', IMAGE);
      if (imagePath != null) break;
    }
    if (imagePath == null) return;

    spritemaps.push({
      source: imagePath,
      json: stripBOM(Assets.getText(jsonPath))
    });
  }

  static function resolveAnimateFile(graphicKey:String, file:String, type:AssetType):Null<String>
  {
    var path:String = Assets.resolvePath('$graphicKey/$file', type);
    return Assets.exists(path, type) ? path : null;
  }

  static function stripBOM(text:String):String
  {
    return (text != null && text.length > 0 && text.charCodeAt(0) == 0xFEFF) ? text.substr(1) : text;
  }

  public static function getPackerAtlas(key:String, ?library:String):FlxAtlasFrames
  {
    return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
  }
}

enum abstract PathsFunction(String)
{
  var MUSIC;
  var INST;
  var VOICES;
  var SOUND;
}

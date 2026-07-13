package backend;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import openfl.utils.Assets;
import openfl.system.System;

#if sys
import sys.FileSystem;
#end

/**
 * Advanced memory management system, specially optimized for Android.
 * Allows assets to be released dynamically to reduce RAM usage.
 */
class MemoryManager
{
    #if android
    private static var isAndroid:Bool = true;
    #else
    private static var isAndroid:Bool = false;
    #end

    /**
     * Removes a specific image from all caches (OpenFL, FlxG, and Paths tracking)
     * @param path Path to the image without the file extension (e.g., "stages/philly/sky")
     * @param removeInstantly If true, destroys the graphic immediately. If false, marks it for later destruction
     */
    public static function removeImageFromMemory(path:String, removeInstantly:Bool = true):Void
    {
        if (path == null || path == '') return;

        // Add the extension if you don't have it
        var imagePath:String = path;
        if (!imagePath.endsWith('.png'))
            imagePath = 'images/$path.png';

        // Search OpenFL assets
        var foundPath:String = Paths.getPath(imagePath, IMAGE);
        
        // Clear the OpenFL Assets Cache
        if (Assets.cache.hasBitmapData(foundPath))
            Assets.cache.removeBitmapData(foundPath);

        // Search the FlxG cache
        var graphic:FlxGraphic = FlxG.bitmap.get(foundPath);
        if (graphic == null)
        {
            // Try the mods path
            #if MODS_ALLOWED
            foundPath = Paths.modsImages(path);
            graphic = FlxG.bitmap.get(foundPath);
            #end
        }

        if (graphic != null)
        {
            // Remove from Paths tracking
            if (Paths.currentTrackedAssets.exists(foundPath))
                Paths.currentTrackedAssets.remove(foundPath);
            
            if (Paths.localTrackedAssets.contains(foundPath))
                Paths.localTrackedAssets.remove(foundPath);

            // Mark for destruction
            graphic.persist = false;
            graphic.destroyOnNoUse = true;

            if (removeInstantly)
            {
                FlxG.bitmap.remove(graphic);
                graphic.destroy();
            }
        }
    }

    /**
     * Removes multiple images from memory at once
     * @param paths Array of image paths
     * @param removeInstantly If true, destroys the graphics immediately
     */
    public static function removeImagesFromMemory(paths:Array<String>, removeInstantly:Bool = true):Void
    {
        if (paths == null) return;
        
        for (path in paths)
            removeImageFromMemory(path, removeInstantly);
    }

    /**
     * Removes a specific character from the character map and frees up its memory
     * @param characterName Character name (e.g., "bf", "dad", "gf")
     * @param removeInstantly If true, destroys the graphic immediately
     */
    public static function removeCharacterFromMemory(characterName:String, removeInstantly:Bool = true):Void
    {
        if (PlayState.instance == null || characterName == null) return;

        var imageFile:String = null;
        var char:objects.Character = null;

        // Search on Boyfriend Map
        if (PlayState.instance.boyfriendMap.exists(characterName))
        {
            char = PlayState.instance.boyfriendMap.get(characterName);
            PlayState.instance.boyfriendGroup.remove(char, true);
            PlayState.instance.boyfriendMap.remove(characterName);
        }
        // Search on Dad Map
        else if (PlayState.instance.dadMap.exists(characterName))
        {
            char = PlayState.instance.dadMap.get(characterName);
            PlayState.instance.dadGroup.remove(char, true);
            PlayState.instance.dadMap.remove(characterName);
        }
        // Search on GF Map
        else if (PlayState.instance.gfMap.exists(characterName))
        {
            char = PlayState.instance.gfMap.get(characterName);
            PlayState.instance.gfGroup.remove(char, true);
            PlayState.instance.gfMap.remove(characterName);
        }

        // If we find the character, destroy it and release its image
        if (char != null)
        {
            imageFile = char.imageFile;
            char.kill();
            char.destroy();

            if (imageFile != null && imageFile != '')
                removeImageFromMemory(imageFile, removeInstantly);
        }
    }

    /**
     * Clears unused UI assets (pixel UI vs. normal UI)
     */
    public static function clearUnusedUI():Void
    {
        #if android
        if (PlayState.instance == null) return;

        if (!PlayState.isPixelStage)
        {
            // Clear the UI pixel if we are in normal stage
            Assets.cache.clear('assets/shared/images/pixelUI');
            removeImageFromMemory('pixelUI/arrows-pixels');
            removeImageFromMemory('pixelUI/arrows-pixels-ends');
            removeImageFromMemory('pixelUI/NOTE_assets');
        }
        else
        {
            // Clear the normal UI if we are in pixel stage
            removeImageFromMemory('NOTE_assets');
            removeImageFromMemory('noteSplashes');
        }
        #end
    }

    /**
     * Remove unused preloaded characters
     */
    public static function clearPreloadedCharacters():Void
    {
        #if android
        // A death character that is rarely used
        removeCharacterFromMemory('bf-dead', true);
        
        // Menu logo
        removeImageFromMemory('logoBumpin', true);
        #end
    }

    /**
     * Aggressive memory cleanup for Android
     * Combines all cleanup functions and forces the garbage collector to run
     */
    public static function aggressiveCleanup():Void
    {
        #if android
        trace('MemoryManager: Performing aggressive memory cleanup...');
        
        // Clear Paths caches
        Paths.clearUnusedMemory();
        
        // Clear unused UI
        clearUnusedUI();
        
        // Clear Preloaded Characters
        clearPreloadedCharacters();
        
        // Force garbage collection
        System.gc();
        #if cpp
        cpp.NativeGc.run(true);
        #end
        
        trace('MemoryManager: Cleaning complete');
        #end
    }

    /**
     * Retrieves the current memory usage in MB (only on systems that support it)
     */
    public static function getMemoryUsage():Float
    {
        #if cpp
        return System.totalMemory / 1024 / 1024;
        #else
        return 0;
        #end
    }

    /**
     * Reports memory usage in the console (useful for debugging)
     */
    public static function reportMemoryUsage():Void
    {
        #if android
        var memoryMB:Float = getMemoryUsage();
        trace('MemoryManager: Current Memory Usage: ${Math.round(memoryMB)}MB');
        #end
    }

    /**
     * Clears all loaded shaders (very useful on Android, where shaders consume a lot of RAM)
     */
    public static function clearShaders():Void
    {
        #if android
        if (PlayState.instance == null) return;
        
        // Clear stage shaders
        if (PlayState.instance.camGame != null && PlayState.instance.camGame.filters != null)
            PlayState.instance.camGame.filters = [];
        
        if (PlayState.instance.camHUD != null && PlayState.instance.camHUD.filters != null)
            PlayState.instance.camHUD.filters = [];
        
        if (PlayState.instance.camOther != null && PlayState.instance.camOther.filters != null)
            PlayState.instance.camOther.filters = [];
        
        trace('MemoryManager: Cleaned-up shaders');
        #end
    }

    /**
     * Automatic memory monitoring for Android
     * Runs an automatic cleanup if memory usage exceeds the specified threshold
     * @param thresholdMB Threshold in MB (default 500MB)
     */
    public static function autoMonitor(thresholdMB:Float = 500):Void
    {
        #if android
        var currentMemory:Float = getMemoryUsage();
        
        if (currentMemory > thresholdMB)
        {
            trace('MemoryManager: Threshold exceeded (${Math.round(currentMemory)} MB > ${thresholdMB} MB). Cleaning in progress...');
            aggressiveCleanup();
        }
        #end
    }
}

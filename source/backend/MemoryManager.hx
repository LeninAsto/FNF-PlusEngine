package backend;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import openfl.utils.Assets;
import openfl.system.System;

#if sys
import sys.FileSystem;
#end

/**
 * Sistema de gestión avanzada de memoria, especialmente optimizado para Android.
 * Permite liberar assets dinámicamente para reducir el consumo de RAM.
 */
class MemoryManager
{
    #if android
    private static var isAndroid:Bool = true;
    #else
    private static var isAndroid:Bool = false;
    #end

    /**
     * Elimina una imagen específica de todos los cachés (OpenFL, FlxG y Paths tracking)
     * @param path Ruta de la imagen sin extensión (ej: "stages/philly/sky")
     * @param removeInstantly Si es true, destruye el gráfico inmediatamente. Si es false, lo marca para destrucción posterior
     */
    public static function removeImageFromMemory(path:String, removeInstantly:Bool = true):Void
    {
        if (path == null || path == '') return;

        // Agregar extensión si no la tiene
        var imagePath:String = path;
        if (!imagePath.endsWith('.png'))
            imagePath = 'images/$path.png';

        // Buscar en assets de OpenFL
        var foundPath:String = Paths.getPath(imagePath, IMAGE);
        
        // Limpiar caché de OpenFL Assets
        if (Assets.cache.hasBitmapData(foundPath))
            Assets.cache.removeBitmapData(foundPath);

        // Buscar en caché de FlxG
        var graphic:FlxGraphic = FlxG.bitmap.get(foundPath);
        if (graphic == null)
        {
            // Intentar con ruta de mods
            #if MODS_ALLOWED
            foundPath = Paths.modsImages(path);
            graphic = FlxG.bitmap.get(foundPath);
            #end
        }

        if (graphic != null)
        {
            // Remover de tracking de Paths
            if (Paths.currentTrackedAssets.exists(foundPath))
                Paths.currentTrackedAssets.remove(foundPath);
            
            if (Paths.localTrackedAssets.contains(foundPath))
                Paths.localTrackedAssets.remove(foundPath);

            // Marcar para destrucción
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
     * Elimina múltiples imágenes de memoria de una vez
     * @param paths Array de rutas de imágenes
     * @param removeInstantly Si es true, destruye los gráficos inmediatamente
     */
    public static function removeImagesFromMemory(paths:Array<String>, removeInstantly:Bool = true):Void
    {
        if (paths == null) return;
        
        for (path in paths)
            removeImageFromMemory(path, removeInstantly);
    }

    /**
     * Elimina un personaje específico del mapa de personajes y libera su memoria
     * @param characterName Nombre del personaje (ej: "bf", "dad", "gf")
     * @param removeInstantly Si es true, destruye el gráfico inmediatamente
     */
    public static function removeCharacterFromMemory(characterName:String, removeInstantly:Bool = true):Void
    {
        if (PlayState.instance == null || characterName == null) return;

        var imageFile:String = null;
        var char:objects.Character = null;

        // Buscar en boyfriend map
        if (PlayState.instance.boyfriendMap.exists(characterName))
        {
            char = PlayState.instance.boyfriendMap.get(characterName);
            PlayState.instance.boyfriendGroup.remove(char, true);
            PlayState.instance.boyfriendMap.remove(characterName);
        }
        // Buscar en dad map
        else if (PlayState.instance.dadMap.exists(characterName))
        {
            char = PlayState.instance.dadMap.get(characterName);
            PlayState.instance.dadGroup.remove(char, true);
            PlayState.instance.dadMap.remove(characterName);
        }
        // Buscar en gf map
        else if (PlayState.instance.gfMap.exists(characterName))
        {
            char = PlayState.instance.gfMap.get(characterName);
            PlayState.instance.gfGroup.remove(char, true);
            PlayState.instance.gfMap.remove(characterName);
        }

        // Si encontramos el personaje, destruirlo y liberar su imagen
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
     * Limpia assets de UI que no se están usando (pixel UI vs UI normal)
     */
    public static function clearUnusedUI():Void
    {
        #if android
        if (PlayState.instance == null) return;

        if (!PlayState.isPixelStage)
        {
            // Limpiar UI pixel si estamos en stage normal
            Assets.cache.clear('assets/shared/images/pixelUI');
            removeImageFromMemory('pixelUI/arrows-pixels');
            removeImageFromMemory('pixelUI/arrows-pixels-ends');
            removeImageFromMemory('pixelUI/NOTE_assets');
        }
        else
        {
            // Limpiar UI normal si estamos en stage pixel
            removeImageFromMemory('NOTE_assets');
            removeImageFromMemory('noteSplashes');
        }
        #end
    }

    /**
     * Elimina personajes precargados que no se usan
     */
    public static function clearPreloadedCharacters():Void
    {
        #if android
        // Personaje de muerte que rara vez se usa
        removeCharacterFromMemory('bf-dead', true);
        
        // Logo del menú
        removeImageFromMemory('logoBumpin', true);
        #end
    }

    /**
     * Limpieza agresiva de memoria para Android
     * Combina todas las funciones de limpieza y fuerza el garbage collector
     */
    public static function aggressiveCleanup():Void
    {
        #if android
        trace('MemoryManager: Ejecutando limpieza agresiva de memoria...');
        
        // Limpiar cachés de Paths
        Paths.clearUnusedMemory();
        
        // Limpiar UI no utilizada
        clearUnusedUI();
        
        // Limpiar personajes precargados
        clearPreloadedCharacters();
        
        // Forzar garbage collection
        System.gc();
        #if cpp
        cpp.NativeGc.run(true);
        #end
        
        trace('MemoryManager: Limpieza completada');
        #end
    }

    /**
     * Obtiene el uso actual de memoria en MB (solo en sistemas que lo soporten)
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
     * Reporta el uso de memoria en consola (útil para debugging)
     */
    public static function reportMemoryUsage():Void
    {
        #if android
        var memoryMB:Float = getMemoryUsage();
        trace('MemoryManager: Uso actual de memoria: ${Math.round(memoryMB)}MB');
        #end
    }

    /**
     * Limpia todos los shaders cargados (muy útil en Android donde los shaders consumen mucha RAM)
     */
    public static function clearShaders():Void
    {
        #if android
        if (PlayState.instance == null) return;
        
        // Limpiar shaders del stage
        if (PlayState.instance.camGame != null && PlayState.instance.camGame.filters != null)
            PlayState.instance.camGame.filters = [];
        
        if (PlayState.instance.camHUD != null && PlayState.instance.camHUD.filters != null)
            PlayState.instance.camHUD.filters = [];
        
        if (PlayState.instance.camOther != null && PlayState.instance.camOther.filters != null)
            PlayState.instance.camOther.filters = [];
        
        trace('MemoryManager: Shaders limpiados');
        #end
    }

    /**
     * Monitoreo automático de memoria para Android
     * Ejecuta limpieza automática si el uso excede el umbral especificado
     * @param thresholdMB Umbral en MB (por defecto 500MB)
     */
    public static function autoMonitor(thresholdMB:Float = 500):Void
    {
        #if android
        var currentMemory:Float = getMemoryUsage();
        
        if (currentMemory > thresholdMB)
        {
            trace('MemoryManager: Umbral excedido (${Math.round(currentMemory)}MB > ${thresholdMB}MB). Ejecutando limpieza...');
            aggressiveCleanup();
        }
        #end
    }
}

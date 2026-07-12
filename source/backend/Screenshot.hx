package backend;

import flixel.FlxG;
import flixel.util.FlxColor;
import sys.FileSystem;

#if windows
import slushithings.windows.WindowsAPI;
#end

/**
 * Screenshot utility for capturing game screenshots
 * Uses native Windows C++ code for reliable screen capture
 * Press F5 to take a screenshot
 */
class Screenshot
{
    public static var screenshotFolder:String = 'screenshots';
    public static var enabled:Bool = true;
    
    private static var lastScreenshotTime:Float = 0;
    private static var screenshotCooldown:Float = 0.5; // Cooldown in seconds to prevent spam
    
    /**
     * Initialize screenshot folder
     */
    public static function init():Void
    {
        #if sys
        var path:String = Sys.getCwd() + screenshotFolder;
        if (!FileSystem.exists(path))
        {
            FileSystem.createDirectory(path);
            trace('Created screenshots folder at: $path');
        }
        #end
    }
    
    /**
     * Capture screenshot of current game state using native Windows C++ code
     * @param customName Optional custom name for the screenshot
     * @return true if screenshot was taken successfully
     */
    public static function capture(?customName:String):Bool
    {
        if (!enabled) return false;
        
        // Check cooldown
        var currentTime:Float = Date.now().getTime();
        if (currentTime - lastScreenshotTime < screenshotCooldown * 1000)
            return false;
        
        lastScreenshotTime = currentTime;
        
        #if windows
        try
        {
            // Generate filename
            var filename:String = customName != null ? customName : generateFilename();
            var fullPath:String = FileSystem.absolutePath(Sys.getCwd() + screenshotFolder + '/' + filename);
            
            // Use native Windows C++ code for screenshot capture
            WindowsAPI.capture(fullPath);
            
            // Show notification
            showNotification('Screenshot saved!');
            
            trace('Saved to $fullPath');
            return true;
        }
        catch (e:Dynamic)
        {
            trace('Error taking screenshot: $e');
            return false;
        }
        #else
        trace('Screenshots are only available on Windows');
        return false;
        #end
    }
    
    /**
     * Generate filename with timestamp
     */
    private static function generateFilename():String
    {
        var date:Date = Date.now();
        var year:String = Std.string(date.getFullYear());
        var month:String = padZero(date.getMonth() + 1);
        var day:String = padZero(date.getDate());
        var hours:String = padZero(date.getHours());
        var minutes:String = padZero(date.getMinutes());
        var seconds:String = padZero(date.getSeconds());
        
        return 'screenshot_${year}-${month}-${day}_${hours}-${minutes}-${seconds}.png';
    }
    
    /**
     * Pad number with zero
     */
    private static function padZero(num:Int):String
    {
        return (num < 10) ? '0$num' : Std.string(num);
    }
    
    /**
     * Show screenshot notification
     */
    private static function showNotification(message:String):Void
    {
        // Create a simple text notification
        if (FlxG.state != null)
        {
            var text:flixel.text.FlxText = new flixel.text.FlxText(0, 50, FlxG.width, message);
            text.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
            text.scrollFactor.set();
            text.cameras = [FlxG.camera];
            FlxG.state.add(text);
            
            // Fade out and remove after 2 seconds
            flixel.tweens.FlxTween.tween(text, {alpha: 0}, 1.5, {
                startDelay: 0.5,
                onComplete: function(_) {
                    text.destroy();
                }
            });
        }
    }
}


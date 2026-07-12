package psychlua;

import openfl.Lib;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.NumTween;
import flixel.tweens.FlxEase;
import flixel.system.scaleModes.RatioScaleMode;
import flixel.util.FlxColor;
import states.PlayState;

#if windows
import slushithings.windows.WindowsAPI;
#end

// Window tweening utilities using optimized FlxTween.num method
// Based on Slushi Engine implementation

class WindowTweens {
    public static function winTweenX(tag:String, targetX:Int, duration:Float = 1, ease:String = "linear", ?onComplete:Void->Void)
    {
        #if windows
        var window = Lib.current.stage.window;
        var variables = MusicBeatState.getVariables();

        if(tag != null)
        {
            var originalTag:String = tag;
            tag = LuaUtils.formatVariable('wintween_$tag');

            FlxTween.cancelTweensOf(window, ["x"]);

            var tween = FlxTween.tween(window, {
                x: targetX
            }, duration, {
                ease: LuaUtils.getTweenEaseByString(ease),
                onComplete: function(_)
                {
                    variables.remove(tag);

                    if (onComplete != null)
                        onComplete();

                    if(PlayState.instance != null)
                        PlayState.instance.callOnLuas('onTweenCompleted', [originalTag, 'window.x']);
                }
            });

            variables.set(tag, tween);
            return tag;
        }
        else
        {
            FlxTween.tween(window, {
                x: targetX
            }, duration, {
                ease: LuaUtils.getTweenEaseByString(ease),
                onComplete: function(_)
                {
                    if (onComplete != null)
                        onComplete();
                }
            });
        }
        #end

        return null;
    }

    public static function winTweenY(tag:String, targetY:Int, duration:Float = 1, ease:String = "linear", ?onComplete:Void->Void)
    {
        #if windows
        var window = Lib.current.stage.window;
        var variables = MusicBeatState.getVariables();
    
        if(tag != null)
        {
            var originalTag:String = tag;
            tag = LuaUtils.formatVariable('wintween_$tag');
        
            FlxTween.cancelTweensOf(window, ["y"]);
        
            var tween = FlxTween.tween(window, {
                y: targetY
            }, duration, {
                ease: LuaUtils.getTweenEaseByString(ease),
                onComplete: function(_)
                {
                    variables.remove(tag);
                
                    if (onComplete != null)
                        onComplete();
                
                    if(PlayState.instance != null)
                        PlayState.instance.callOnLuas('onTweenCompleted', [originalTag, 'window.y']);
                }
            });
        
            variables.set(tag, tween);
            return tag;
        }
        else
        {
            FlxTween.tween(window, {
                y: targetY
            }, duration, {
                ease: LuaUtils.getTweenEaseByString(ease),
                onComplete: function(_)
                {
                    if (onComplete != null)
                        onComplete();
                }
            });
        }
        #end
    
        return null;
    }
    
    public static function setWindowBorderless(enable:Bool) {
        #if windows
        var window = Lib.current.stage.window;
        window.borderless = enable;
        #end
    }

    public static function setWindowX(x:Int) {
        #if windows
        var window = Lib.current.stage.window;
        window.x = x;
        #end
    }

    public static function setWindowY(y:Int) {
        #if windows
        var window = Lib.current.stage.window;
        window.y = y;
        #end
    }

    public static function setWindowSize(width:Int, height:Int) {
        #if windows
        var window = Lib.current.stage.window;
        window.resize(width, height);
        #end
    }

    public static function getWindowX():Int {
        #if windows
        var window = Lib.current.stage.window;
        return window.x;
        #else
        return 0;
        #end
    }

    public static function getWindowY():Int {
        #if windows
        var window = Lib.current.stage.window;
        return window.y;
        #else
        return 0;
        #end
    }

    public static function getWindowWidth():Int {
        #if windows
        var window = Lib.current.stage.window;
        return window.width;
        #else
        return FlxG.width;
        #end
    }

    public static function getWindowHeight():Int {
        #if windows
        var window = Lib.current.stage.window;
        return window.height;
        #else
        return FlxG.height;
        #end
    }

    public static function centerWindow() {
        #if windows
        var window = Lib.current.stage.window;
        var screenWidth = Lib.application.window.stage.fullScreenWidth;
        var screenHeight = Lib.application.window.stage.fullScreenHeight;
        window.x = Std.int((screenWidth - window.width) / 2);
        window.y = Std.int((screenHeight - window.height) / 2);
        #end
    }

    public static function setWindowTitle(title:String) {
        #if windows
        var window = Lib.current.stage.window;
        window.title = title;
        #end
    }

    public static function getWindowTitle():String {
        #if windows
        var window = Lib.current.stage.window;
        return window.title;
        #else
        return "";
        #end
    }

    public static function setWindowIcon(iconPath:String) {
        #if windows
        try {
            var window = Lib.current.stage.window;
            var iconBitmap = openfl.display.BitmapData.fromFile(iconPath);
            if (iconBitmap != null) {
                window.setIcon(lime.graphics.Image.fromBitmapData(iconBitmap));
            }
        } catch (e:Dynamic) {
            trace('Error setting window icon: $e');
        }
        #end
    }

    public static function setWindowResizable(enable:Bool) {
        #if windows
        var window = Lib.current.stage.window;
        window.resizable = enable;
        #end
    }

    public static function randomizeWindowPosition(minX:Int = 0, maxX:Int = -1, minY:Int = 0, maxY:Int = -1) {
        #if windows
        var window = Lib.current.stage.window;
        var screenWidth = Lib.application.window.stage.fullScreenWidth;
        var screenHeight = Lib.application.window.stage.fullScreenHeight;
        
        if (maxX == -1) maxX = Std.int(screenWidth - window.width);
        if (maxY == -1) maxY = Std.int(screenHeight - window.height);
        
        minX = Std.int(Math.min(minX, maxX));
        minY = Std.int(Math.min(minY, maxY));
        
        var randomX = Std.int(minX + Math.random() * (maxX - minX));
        var randomY = Std.int(minY + Math.random() * (maxY - minY));
        
        window.x = randomX;
        window.y = randomY;
        #end
    }

    public static function getScreenResolution():{width:Int, height:Int} {
        return {
            width: Std.int(Lib.application.window.stage.fullScreenWidth),
            height: Std.int(Lib.application.window.stage.fullScreenHeight)
        };
    }

    public static function setWindowFullscreen(enable:Bool) {
        #if windows
        var window = Lib.current.stage.window;
        window.fullscreen = enable;
        #end
    }

    public static function isWindowFullscreen():Bool {
        #if windows
        var window = Lib.current.stage.window;
        return window.fullscreen;
        #else
        return false;
        #end
    }

    public static function saveWindowState():String {
        #if windows
        var window = Lib.current.stage.window;
        var state = {
            x: window.x,
            y: window.y,
            width: window.width,
            height: window.height,
            borderless: window.borderless,
            resizable: window.resizable,
            title: window.title
        };
        return haxe.Json.stringify(state);
        #else
        return "{}";
        #end
    }

    public static function loadWindowState(stateJson:String) {
        #if windows
        try {
            var state = haxe.Json.parse(stateJson);
            var window = Lib.current.stage.window;
            
            if (state.x != null) window.x = state.x;
            if (state.y != null) window.y = state.y;
            if (state.width != null && state.height != null) {
                window.resize(state.width, state.height);
                FlxG.resizeGame(state.width, state.height);
            }
            if (state.borderless != null) window.borderless = state.borderless;
            if (state.resizable != null) window.resizable = state.resizable;
            if (state.title != null) window.title = state.title;
        } catch (e:Dynamic) {
            trace('Error loading window state: $e');
        }
        #end
    }

    public static function winTweenSize(targetW:Int, targetH:Int, duration:Float = 1, ease:String = "linear", ?onComplete:Void->Void)
    {
        #if windows
        var window = Lib.application.window;

        FlxTween.cancelTweensOf(window);

        FlxG.scaleMode = new RatioScaleMode(true);

        FlxTween.tween(window, {
            width: targetW,
            height: targetH
        }, duration, {
            ease: LuaUtils.getTweenEaseByString(ease),
            onComplete: function(_)
            {
                trace("FINAL");
                trace("Target: " + targetW + "x" + targetH);
                trace("Window: " + window.width + "x" + window.height);

                if (onComplete != null)
                    onComplete();
            }
        });
        #end
    }

    public static function winResizeCenter(width:Int, height:Int, ?skip:Bool = false, ?markAsResized:Bool = true) {
        #if windows
        if (markAsResized && PlayState.instance != null) {
            PlayState.instance.windowResizedByScript = true;
        }
        var window = Lib.application.window;
        var winYRatio = 1;
        var winY = height * winYRatio;
        var winX = width * winYRatio;

        FlxTween.cancelTweensOf(window);
        if (!skip) {
            FlxTween.tween(window, {
                width: winX,
                height: winY,
                y: Math.floor((Lib.application.window.stage.fullScreenHeight / 2) - (winY / 2)),
                x: Math.floor((Lib.application.window.stage.fullScreenWidth / 2) - (winX / 2)) + (Lib.application.window.stage.fullScreenWidth * Math.floor(window.x / (Lib.application.window.stage.fullScreenWidth)))
            }, 0.4, {
                ease: FlxEase.quadInOut,
                onComplete: function(_) {
                    if (PlayState.instance != null && PlayState.instance.camHUD != null) {
                        PlayState.instance.camHUD.fade(FlxColor.BLACK, 0, true);
                    }
                }
            });
        } else {
            trace("resizeCenter target: " + width + "x" + height);
            FlxG.resizeWindow(width, height);
            trace("resizeCenter result: " + window.width + "x" + window.height);
            window.y = Math.floor((Lib.application.window.stage.fullScreenHeight / 2) - (winY / 2));
            window.x = Std.int(Math.floor((Lib.application.window.stage.fullScreenWidth / 2) - (winX / 2)) + (Lib.application.window.stage.fullScreenWidth * Math.floor(window.x / (Lib.application.window.stage.fullScreenWidth))));
        }
        trace("Stage: " +
                Lib.current.stage.stageWidth +
                "x" +
                Lib.current.stage.stageHeight);
        FlxG.scaleMode = new RatioScaleMode(true);
        window.resizable = width == 1280;
        #end
    }

    public static function getWindowState():String {
        #if windows
        try {
            var window = Lib.current.stage.window;
            if (window.fullscreen) return "fullscreen";
            return "normal";
        } catch (e:Dynamic) {
            trace('Error getting window state: $e');
            return "error";
        }
        #else
        return "normal";
        #end
    }

    public static function setDesktopWallpaper(path:String) {
        #if windows
        try {
            WindowsAPI.changeWindowsWallpaper(path);
        } catch (e:Dynamic) {
            trace('Error setting wallpaper: $e');
        }
        #end
    }

    public static function hideDesktopIcons(hide:Bool) {
        #if windows
        try {
            WindowsAPI.hideDesktopIcons(hide);
        } catch (e:Dynamic) {
            trace('Error hiding desktop icons: $e');
        }
        #end
    }

    public static function hideTaskBar(hide:Bool) {
        #if windows
        try {
            WindowsAPI.hideTaskBar(hide);
        } catch (e:Dynamic) {
            trace('Error hiding taskbar: $e');
        }
        #end
    }

    public static function moveDesktopElements(x:Int, y:Int) {
        #if windows
        try {
            WindowsAPI.moveDesktopElements(x, y);
        } catch (e:Dynamic) {
            trace('Error moving desktop elements: $e');
        }
        #end
    }

    // Tween desktop icons X position using FlxTween.num (optimized)
    public static function tweenDesktopX(toX:Int, duration:Float = 1, ease:String = "linear", ?onComplete:Void->Void) {
        #if windows
        try {
            var startX:Int = WindowsAPI.getDesktopWindowsXPos();
            var tween:NumTween = FlxTween.num(startX, toX, duration, {
                ease: LuaUtils.getTweenEaseByString(ease),
                onComplete: function(_) {
                    if (onComplete != null) onComplete();
                }
            });
            tween.onUpdate = function(t:FlxTween) {
                var currentY:Int = WindowsAPI.getDesktopWindowsYPos();
                WindowsAPI.moveDesktopElements(Std.int(tween.value), currentY);
            };
        } catch (e:Dynamic) {
            trace('Error tweening desktop X: $e');
        }
        #end
    }

    // Tween desktop icons Y position using FlxTween.num (optimized)
    public static function tweenDesktopY(toY:Int, duration:Float = 1, ease:String = "linear", ?onComplete:Void->Void) {
        #if windows
        try {
            var startY:Int = WindowsAPI.getDesktopWindowsYPos();
            var tween:NumTween = FlxTween.num(startY, toY, duration, {
                ease: LuaUtils.getTweenEaseByString(ease),
                onComplete: function(_) {
                    if (onComplete != null) onComplete();
                }
            });
            tween.onUpdate = function(t:FlxTween) {
                var currentX:Int = WindowsAPI.getDesktopWindowsXPos();
                WindowsAPI.moveDesktopElements(currentX, Std.int(tween.value));
            };
        } catch (e:Dynamic) {
            trace('Error tweening desktop Y: $e');
        }
        #end
    }

    public static function setDesktopTransparency(alpha:Float) {
        #if windows
        try {
            var clampedAlpha = Math.max(0.0, Math.min(1.0, alpha));
            WindowsAPI.setDesktopTransparency(clampedAlpha);
        } catch (e:Dynamic) {
            trace('Error setting desktop transparency: $e');
        }
        #end
    }

    public static function setTaskBarTransparency(alpha:Float) {
        #if windows
        try {
            var clampedAlpha = Math.max(0.0, Math.min(1.0, alpha));
            WindowsAPI.setTaskBarTransparency(clampedAlpha);
        } catch (e:Dynamic) {
            trace('Error setting taskbar transparency: $e');
        }
        #end
    }

    // Tween desktop transparency using FlxTween.num (optimized)
    public static function tweenDesktopAlpha(fromAlpha:Float, toAlpha:Float, duration:Float = 1, ease:String = "linear", ?onComplete:Void->Void) {
        #if windows
        try {
            var tween:NumTween = FlxTween.num(fromAlpha, toAlpha, duration, {
                ease: LuaUtils.getTweenEaseByString(ease),
                onComplete: function(_) {
                    if (onComplete != null) onComplete();
                }
            });
            tween.onUpdate = function(t:FlxTween) {
                var clampedAlpha = Math.max(0.0, Math.min(1.0, tween.value));
                WindowsAPI.setDesktopTransparency(clampedAlpha);
            };
        } catch (e:Dynamic) {
            trace('Error tweening desktop transparency: $e');
        }
        #end
    }

    // Tween taskbar transparency using FlxTween.num (optimized)
    public static function tweenTaskBarAlpha(fromAlpha:Float, toAlpha:Float, duration:Float = 1, ease:String = "linear", ?onComplete:Void->Void) {
        #if windows
        try {
            var tween:NumTween = FlxTween.num(fromAlpha, toAlpha, duration, {
                ease: LuaUtils.getTweenEaseByString(ease),
                onComplete: function(_) {
                    if (onComplete != null) onComplete();
                }
            });
            tween.onUpdate = function(t:FlxTween) {
                var clampedAlpha = Math.max(0.0, Math.min(1.0, tween.value));
                WindowsAPI.setTaskBarTransparency(clampedAlpha);
            };
        } catch (e:Dynamic) {
            trace('Error tweening taskbar transparency: $e');
        }
        #end
    }

    public static function getDesktopWindowsXPos():Int {
        #if windows
        try {
            return WindowsAPI.getDesktopWindowsXPos();
        } catch (e:Dynamic) {
            trace('Error getting desktop X position: $e');
            return 0;
        }
        #else
        return 0;
        #end
    }

    public static function getDesktopWindowsYPos():Int {
        #if windows
        try {
            return WindowsAPI.getDesktopWindowsYPos();
        } catch (e:Dynamic) {
            trace('Error getting desktop Y position: $e');
            return 0;
        }
        #else
        return 0;
        #end
    }

    public static function setWindowBorderColor(r:Int, g:Int, b:Int) {
        #if windows
        try {
            WindowsAPI.setWindowBorderColor(r, g, b);
        } catch (e:Dynamic) {
            trace('Error setting window border color: $e');
        }
        #end
    }

    // Tween window border color using FlxTween.num (optimized, Slushi Engine method)
    public static function tweenWindowBorderColor(fromR:Int, fromG:Int, fromB:Int, toR:Int, toG:Int, toB:Int, duration:Float = 1, ease:String = "linear", ?onComplete:Void->Void) {
        #if windows
        try {
            var fromColor:Array<Int> = [fromR, fromG, fromB];
            var toColor:Array<Int> = [toR, toG, toB];
            
            var tween:NumTween = FlxTween.num(0, 1, duration, {
                ease: LuaUtils.getTweenEaseByString(ease),
                onComplete: function(_) {
                    if (onComplete != null) onComplete();
                }
            });
            
            tween.onUpdate = function(t:FlxTween) {
                var interpolatedColor:Array<Int> = [];
                for (i in 0...3) {
                    var newValue:Int = fromColor[i] + Std.int((toColor[i] - fromColor[i]) * tween.value);
                    newValue = Std.int(Math.max(0, Math.min(255, newValue)));
                    interpolatedColor.push(newValue);
                }
                WindowsAPI.setWindowBorderColor(interpolatedColor[0], interpolatedColor[1], interpolatedColor[2]);
            };
        } catch (e:Dynamic) {
            trace('Error tweening window border color: $e');
        }
        #end
    }

    public static function setWindowOpacity(alpha:Float) {
        #if windows
        try {
            var clampedAlpha = Math.max(0.0, Math.min(1.0, alpha));
            WindowsAPI.setWindowOppacity(clampedAlpha);
        } catch (e:Dynamic) {
            trace('Error setting window opacity: $e');
        }
        #end
    }

    public static function getWindowOpacity():Float {
        #if windows
        try {
            return WindowsAPI.getWindowOppacity();
        } catch (e:Dynamic) {
            trace('Error getting window opacity: $e');
            return 1.0;
        }
        #else
        return 1.0;
        #end
    }

    // Tween window opacity using FlxTween.num (optimized)
    public static function tweenWindowOpacity(fromAlpha:Float, toAlpha:Float, duration:Float = 1, ease:String = "linear", ?onComplete:Void->Void) {
        #if windows
        try {
            var tween:NumTween = FlxTween.num(fromAlpha, toAlpha, duration, {
                ease: LuaUtils.getTweenEaseByString(ease),
                onComplete: function(_) {
                    if (onComplete != null) onComplete();
                }
            });
            tween.onUpdate = function(t:FlxTween) {
                var clampedAlpha = Math.max(0.0, Math.min(1.0, tween.value));
                WindowsAPI.setWindowOppacity(clampedAlpha);
            };
        } catch (e:Dynamic) {
            trace('Error tweening window opacity: $e');
        }
        #end
    }

    public static function showNotification(title:String, message:String) {
        #if windows
        try {
            WindowsAPI.sendWindowsNotification(message, title);
        } catch (e:Dynamic) {
            trace('Error showing notification: $e');
        }
        #end
    }

    public static function resetSystemChanges() {
        #if windows
        try {
            WindowsAPI.hideDesktopIcons(false);
            WindowsAPI.hideTaskBar(false);
            WindowsAPI.moveDesktopElements(0, 0);
            WindowsAPI.setDesktopTransparency(1.0);
            WindowsAPI.setTaskBarTransparency(1.0);
            
            if (WindowsAPI.changedWallpaper) {
                WindowsAPI.setOldWindowsWallpaper();
            }
        } catch (e:Dynamic) {
            trace('Error resetting system changes: $e');
        }
        #end
    }

    public static function changeWindowsWallpaper(path:String) {
        #if windows
        try {
            WindowsAPI.changeWindowsWallpaper(path);
        } catch (e:Dynamic) {
            trace('Error changing wallpaper: $e');
        }
        #end
    }

    public static function saveCurrentWallpaper() {
        #if windows
        try {
            WindowsAPI.saveCurrentWindowsWallpaper();
        } catch (e:Dynamic) {
            trace('Error saving current wallpaper: $e');
        }
        #end
    }

    public static function restoreOldWallpaper() {
        #if windows
        try {
            WindowsAPI.setOldWindowsWallpaper();
        } catch (e:Dynamic) {
            trace('Error restoring old wallpaper: $e');
        }
        #end
    }

    public static function captureScreenshot(path:String) {
        #if windows
        try {
            WindowsAPI.capture(path);
        } catch (e:Dynamic) {
            trace('Error capturing screenshot: $e');
        }
        #end
    }

    public static function getWindowsVersion():Int {
        #if windows
        return WindowsAPI.getWindowsVersion();
        #else
        return 0;
        #end
    }
}


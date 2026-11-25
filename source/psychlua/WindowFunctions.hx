package psychlua;

#if WINDOWS_FUNCTIONS_ALLOWED
import psychlua.backend.WindowTweens;
import backend.window.WindowManager;
#if GDI_ENABLED
import slushithings.windows.WindowsAPI;
#end
#end

class WindowFunctions
{
	public static function implement(funk:FunkinLua) {
		#if WINDOWS_FUNCTIONS_ALLOWED
		var lua = funk.lua;

		// Desktop window APIs. A true return means the request was submitted;
		// the window manager can still reject it.
		Lua_helper.add_callback(lua, "getWindowBackend", function() return WindowManager.backend());
		Lua_helper.add_callback(lua, "windowSupports", function(feature:String) return WindowManager.supports(feature));
		Lua_helper.add_callback(lua, "createGameWindow", function(id:String, width:Int, height:Int, title:String, ?alwaysOnTop:Bool = false) return WindowManager.create(id, width, height, title, alwaysOnTop, funk));
		Lua_helper.add_callback(lua, "setGameWindowText", function(id:String, value:String) return WindowManager.setText(id, value));
		Lua_helper.add_callback(lua, "moveGameWindow", function(id:String, x:Int, y:Int) return WindowManager.move(id, x, y));
		Lua_helper.add_callback(lua, "resizeGameWindow", function(id:String, width:Int, height:Int) return WindowManager.resize(id, width, height));
		Lua_helper.add_callback(lua, "setGameWindowOpacity", function(id:String, alpha:Float) return WindowManager.setOpacity(id, alpha));
		Lua_helper.add_callback(lua, "tweenGameWindow", function(id:String, property:String, target:Float, duration:Float, ?ease:String = "linear") return WindowManager.tween(id, property, target, duration, ease));
		Lua_helper.add_callback(lua, "closeGameWindow", function(id:String) return WindowManager.close(id));

		// Window Tween Functions
		Lua_helper.add_callback(lua, "winTweenSize", function(width:Int, height:Int, duration:Float = 1, ease:String = "linear") {
			return WindowTweens.winTweenSize(width, height, duration, ease);
		});

		Lua_helper.add_callback(lua, "winTweenX", function(tag:String, targetX:Int, duration:Float = 1, ease:String = "linear") {
			return WindowTweens.winTweenX(tag, targetX, duration, ease);
		});

		Lua_helper.add_callback(lua, "winTweenY", function(tag:String, targetY:Int, duration:Float = 1, ease:String = "linear") {
			return WindowTweens.winTweenY(tag, targetY, duration, ease);
		});

		// Window Position Functions (Immediate)
		Lua_helper.add_callback(lua, "setWindowX", function(x:Int) {
			WindowTweens.setWindowX(x);
		});

		Lua_helper.add_callback(lua, "setWindowY", function(y:Int) {
			WindowTweens.setWindowY(y);
		});

		Lua_helper.add_callback(lua, "setWindowSize", function(width:Int, height:Int) {
			WindowTweens.setWindowSize(width, height);
		});

		Lua_helper.add_callback(lua, "setWindowBounds", function(x:Int, y:Int, width:Int, height:Int) {
			WindowTweens.setWindowBounds(x, y, width, height);
		});

		Lua_helper.add_callback(lua, "resizeGame", function(width:Int, height:Int) {
			WindowTweens.resizeGame(width, height);
		});

		Lua_helper.add_callback(lua, "setGameScaleMode", function(mode:String) {
			WindowTweens.setGameScaleMode(mode);
		});

		Lua_helper.add_callback(lua, "restoreGameScaleMode", function() {
			WindowTweens.restoreGameScaleMode();
		});

		// Window Information Functions
		Lua_helper.add_callback(lua, "getWindowX", function() {
			return WindowTweens.getWindowX();
		});

		Lua_helper.add_callback(lua, "getWindowY", function() {
			return WindowTweens.getWindowY();
		});

		Lua_helper.add_callback(lua, "getWindowWidth", function() {
			return WindowTweens.getWindowWidth();
		});

		Lua_helper.add_callback(lua, "getWindowHeight", function() {
			return WindowTweens.getWindowHeight();
		});

		// Window State Control Functions
		Lua_helper.add_callback(lua, "centerWindow", function() {
			WindowTweens.centerWindow();
		});

		// Window Properties Functions
		Lua_helper.add_callback(lua, "setWindowTitle", function(title:String) {
			WindowTweens.setWindowTitle(title);
		});

		Lua_helper.add_callback(lua, "getWindowTitle", function() {
			return WindowTweens.getWindowTitle();
		});

		Lua_helper.add_callback(lua, "setWindowIcon", function(iconPath:String) {
			WindowTweens.setWindowIcon(iconPath);
		});

		Lua_helper.add_callback(lua, "setWindowResizable", function(enable:Bool) {
			WindowTweens.setWindowResizable(enable);
		});

		Lua_helper.add_callback(lua, "randomizeWindowPosition", function(?minX:Int = 0, ?maxX:Int = -1, ?minY:Int = 0, ?maxY:Int = -1) {
			WindowTweens.randomizeWindowPosition(minX, maxX, minY, maxY);
		});

		// Screen Information Functions
		Lua_helper.add_callback(lua, "getScreenWidth", function() {
			return WindowTweens.getScreenResolution().width;
		});

		Lua_helper.add_callback(lua, "getScreenHeight", function() {
			return WindowTweens.getScreenResolution().height;
		});

		Lua_helper.add_callback(lua, "getScreenResolution", function() {
			return WindowTweens.getScreenResolution();
		});

		// Window Fullscreen Functions
		Lua_helper.add_callback(lua, "setWindowFullscreen", function(enable:Bool) {
			WindowTweens.setWindowFullscreen(enable);
		});

		Lua_helper.add_callback(lua, "isWindowFullscreen", function() {
			return WindowTweens.isWindowFullscreen();
		});

		// Window State Management Functions
		Lua_helper.add_callback(lua, "saveWindowState", function() {
			return WindowTweens.saveWindowState();
		});

		Lua_helper.add_callback(lua, "loadWindowState", function(stateJson:String) {
			WindowTweens.loadWindowState(stateJson);
		});

		// === NUEVAS FUNCIONES CON WINDOWS API ===

		// Window State Information Functions
		Lua_helper.add_callback(lua, "getWindowState", function() {
			return WindowTweens.getWindowState();
		});

		// Desktop/System Control Functions
		Lua_helper.add_callback(lua, "setDesktopWallpaper", function(path:String) {
			WindowTweens.setDesktopWallpaper(path);
		});

		Lua_helper.add_callback(lua, "hideDesktopIcons", function(hide:Bool) {
			WindowTweens.hideDesktopIcons(hide);
		});

		Lua_helper.add_callback(lua, "hideTaskBar", function(hide:Bool) {
			WindowTweens.hideTaskBar(hide);
		});

		Lua_helper.add_callback(lua, "moveDesktopElements", function(x:Int, y:Int) {
			WindowTweens.moveDesktopElements(x, y);
		});

		Lua_helper.add_callback(lua, "setDesktopTransparency", function(alpha:Float) {
			WindowTweens.setDesktopTransparency(alpha);
		});

		Lua_helper.add_callback(lua, "setTaskBarTransparency", function(alpha:Float) {
			WindowTweens.setTaskBarTransparency(alpha);
		});


		// System Notification Functions
		Lua_helper.add_callback(lua, "showNotification", function(title:String, message:String) {
			WindowTweens.showNotification(title, message);
		});

		// System Reset Functions
		Lua_helper.add_callback(lua, "resetSystemChanges", function() {
			WindowTweens.resetSystemChanges();
		});

		Lua_helper.add_callback(lua, "getDesktopWindowsXPos", function() {
			return WindowTweens.getDesktopWindowsXPos();
		});

		Lua_helper.add_callback(lua, "getDesktopWindowsYPos", function() {
			return WindowTweens.getDesktopWindowsYPos();
		});

		Lua_helper.add_callback(lua, "setWindowBorderColor", function(r:Int, g:Int, b:Int) {
			WindowTweens.setWindowBorderColor(r, g, b);
		});

		Lua_helper.add_callback(lua, "setWindowOpacity", function(alpha:Float) {
			WindowTweens.setWindowOpacity(alpha);
		});

		Lua_helper.add_callback(lua, "getWindowOpacity", function() {
			return WindowTweens.getWindowOpacity();
		});

		Lua_helper.add_callback(lua, "changeWindowsWallpaper", function(path:String) {
			WindowTweens.changeWindowsWallpaper(path);
		});

		Lua_helper.add_callback(lua, "saveCurrentWallpaper", function() {
			WindowTweens.saveCurrentWallpaper();
		});

		Lua_helper.add_callback(lua, "restoreOldWallpaper", function() {
			WindowTweens.restoreOldWallpaper();
		});

		Lua_helper.add_callback(lua, "captureScreenshot", function(path:String) {
			WindowTweens.captureScreenshot(path);
		});

		Lua_helper.add_callback(lua, "getWindowsVersion", function() {
			return WindowTweens.getWindowsVersion();
		});

		// Optimized Tween Functions using FlxTween.num
		Lua_helper.add_callback(lua, "tweenWindowBorderColor", function(fromR:Int, fromG:Int, fromB:Int, toR:Int, toG:Int, toB:Int, duration:Float = 1, ease:String = "linear") {
			WindowTweens.tweenWindowBorderColor(fromR, fromG, fromB, toR, toG, toB, duration, ease);
		});

		Lua_helper.add_callback(lua, "tweenWindowOpacity", function(fromAlpha:Float, toAlpha:Float, duration:Float = 1, ease:String = "linear") {
			WindowTweens.tweenWindowOpacity(fromAlpha, toAlpha, duration, ease);
		});

		Lua_helper.add_callback(lua, "tweenDesktopX", function(toX:Int, duration:Float = 1, ease:String = "linear") {
			WindowTweens.tweenDesktopX(toX, duration, ease);
		});

		Lua_helper.add_callback(lua, "tweenDesktopY", function(toY:Int, duration:Float = 1, ease:String = "linear") {
			WindowTweens.tweenDesktopY(toY, duration, ease);
		});

		Lua_helper.add_callback(lua, "tweenDesktopAlpha", function(fromAlpha:Float, toAlpha:Float, duration:Float = 1, ease:String = "linear") {
			WindowTweens.tweenDesktopAlpha(fromAlpha, toAlpha, duration, ease);
		});

		Lua_helper.add_callback(lua, "tweenTaskBarAlpha", function(fromAlpha:Float, toAlpha:Float, duration:Float = 1, ease:String = "linear") {
			WindowTweens.tweenTaskBarAlpha(fromAlpha, toAlpha, duration, ease);
		});

		Lua_helper.add_callback(lua, "hideWindowBorder", function(enable:Bool) {
			WindowTweens.setWindowBorderless(enable);
		});

		Lua_helper.add_callback(lua, "setWinRCenter", function(width:Int, height:Int, ?skip:Bool = false) {
			WindowTweens.winResizeCenter(width, height, skip);
		});

		#if GDI_ENABLED
		Lua_helper.add_callback(lua, "initGDIThread", function() {
			WindowsAPI.initGDIThread();
		});

		Lua_helper.add_callback(lua, "stopGDIThread", function() {
			WindowsAPI.stopGDIThread();
		});

		Lua_helper.add_callback(lua, "pauseGDIThread", function(pause:Bool) {
			WindowsAPI.pauseGDIThread(pause);
		});

		Lua_helper.add_callback(lua, "isGDIThreadRunning", function() {
			return WindowsAPI.isGDIThreadRunning();
		});

		Lua_helper.add_callback(lua, "getGDIElapsedTime", function() {
			return WindowsAPI.getGDIElapsedTime();
		});

		Lua_helper.add_callback(lua, "prepareGDIEffect", function(effect:String, ?wait:Float = 0) {
			WindowsAPI.prepareGDIEffect(effect, wait);
		});

		Lua_helper.add_callback(lua, "enableGDIEffect", function(effect:String, ?enabled:Bool = true) {
			WindowsAPI.enableGDIEffect(effect, enabled);
		});

		Lua_helper.add_callback(lua, "removeGDIEffect", function(effect:String) {
			WindowsAPI.removeGDIEffect(effect);
		});

		Lua_helper.add_callback(lua, "setGDIEffectWaitTime", function(effect:String, wait:Float) {
			WindowsAPI.setGDIEffectWaitTime(effect, wait);
		});

		Lua_helper.add_callback(lua, "setGDIElapsedTime", function(elapsed:Float) {
			WindowsAPI.setGDIElapsedTime(elapsed);
		});
		#end
		#end
	}
}

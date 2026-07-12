package psychlua;

#if WINDOWS_FUNCTIONS_ALLOWED
import slushithings.windows.WindowsAPI;
#end

class WindowsGDIFunctions
{
	public static function implement(funk:FunkinLua) {
		#if WINDOWS_FUNCTIONS_ALLOWED
		var lua = funk.lua;

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
	}
}


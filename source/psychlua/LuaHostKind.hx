#if LUA_ALLOWED
package psychlua;

enum abstract LuaHostKind(String) from String to String
{
	var PLAYSTATE = "playstate";
	var STATE = "state";
	var SUBSTATE = "substate";
	var GLOBAL = "global";
}
#end

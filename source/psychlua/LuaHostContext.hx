#if LUA_ALLOWED
package psychlua;

class LuaHostContext
{
	public var host:Dynamic;
	public var parentState:Dynamic;
	public var name:String;
	public var kind:LuaHostKind;
	public var variables:Map<String, Dynamic>;
	public var scriptList:Array<FunkinLua>;

	public function new(kind:LuaHostKind, name:String, host:Dynamic, ?parentState:Dynamic,
			?variables:Map<String, Dynamic>, ?scriptList:Array<FunkinLua>)
	{
		this.kind = kind;
		this.name = name;
		this.host = host;
		this.parentState = parentState;
		this.variables = variables != null ? variables : new Map<String, Dynamic>();
		this.scriptList = scriptList;
	}

	public inline function isPlayState():Bool
		return kind == PLAYSTATE;
}
#end

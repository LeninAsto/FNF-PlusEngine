package funkin.plus;

import flixel.FlxG;
import flixel.FlxState;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEvent.StateChangeScriptEvent;
import funkin.modding.events.ScriptEvent.UpdateScriptEvent;
import funkin.modding.module.ModuleHandler;

/**
 * Dispatches a restrained subset of VSlice module events while the player is in
 * Plus/Psych states. This lets VSlice modules decorate Plus menus without
 * forcing those menus to be replaced by the official VSlice UI.
 */
class VSlicePlusStateBridge
{
	static var createdState:FlxState = null;
	static var skipBackendUpdate:Bool = false;

	public static function create(state:FlxState):Void
	{
		if (state == null || !supportsState(state)) return;
		if (!VSliceRuntime.shouldUseVSliceRuntime()) return;
		if (!isStateReadyForPlusModules(state)) return;
		if (createdState == state) return;

		VSliceRuntime.ensureReady();
		if (!VSliceRuntime.active) return;

		FlxG.keys.enabled = true;
		createdState = state;
		ModuleHandler.callPlusStateEvent(new StateChangeScriptEvent(STATE_CHANGE_END, state, true));
		ModuleHandler.callPlusStateEvent(new ScriptEvent(STATE_CREATE, false));
	}

	public static function update(elapsed:Float, early:Bool = false):Void
	{
		if (!canDispatchFor(FlxG.state)) return;

		if (!early && skipBackendUpdate)
		{
			skipBackendUpdate = false;
			return;
		}
		if (early) skipBackendUpdate = true;

		ModuleHandler.callPlusStateEvent(new UpdateScriptEvent(elapsed));
	}

	public static function destroy(state:FlxState):Void
	{
		if (createdState != state) return;
		if (!VSliceRuntime.active) return;

		ModuleHandler.callPlusStateEvent(new StateChangeScriptEvent(STATE_CHANGE_BEGIN, null, true));
		createdState = null;
	}

	public static function supportsState(state:FlxState):Bool
	{
		return Std.isOfType(state, states.MainMenuState)
			|| Std.isOfType(state, states.FreeplayState)
			|| Std.isOfType(state, states.FreeplayState_Psych)
			|| Std.isOfType(state, states.StoryMenuState);
	}

	static function canDispatchFor(state:FlxState):Bool
	{
		if (state == null || !supportsState(state)) return false;
		if (!VSliceRuntime.shouldUseVSliceRuntime()) return false;

		VSliceRuntime.ensureReady();
		return VSliceRuntime.active;
	}

	static function isStateReadyForPlusModules(state:FlxState):Bool
	{
		if (Std.isOfType(state, states.MainMenuState))
		{
			var mainMenu:states.MainMenuState = cast state;
			return mainMenu.menuItems != null;
		}

		return true;
	}
}

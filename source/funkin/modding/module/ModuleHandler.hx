package funkin.modding.module;

import funkin.util.SortUtil;
import funkin.modding.events.ScriptEvent.UpdateScriptEvent;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.modding.module.Module;
import funkin.modding.module.ScriptedModule;
import flixel.FlxG;

/**
 * Utility functions for loading and manipulating active modules.
 */
@:nullSafety
class ModuleHandler
{
  static final moduleCache:Map<String, Module> = new Map<String, Module>();
  static var modulePriorityOrder:Array<String> = [];
  static var callbacksBuilt:Bool = false;

  /**
   * Parses and preloads the game's stage data and scripts when the game starts.
   *
   * If you want to force stages to be reloaded, you can just call this function again.
   */
  public static function loadModuleCache():Void
  {
    // Clear any stages that are cached if there were any.
    clearModuleCache();
    trace("[MODULEHANDLER] Loading module cache...");

    var scriptedModuleClassNames:Array<String> = ScriptedModule.listScriptClasses();
    trace(' Instantiating ${scriptedModuleClassNames.length} modules...');
    for (moduleCls in scriptedModuleClassNames)
    {
      var module:Null<Module> = ScriptedModule.scriptInit(moduleCls, moduleCls);
      if (module != null)
      {
        trace('   Loaded module: ${moduleCls}');

        // Then store it.
        addToModuleCache(module);
      }
      else
      {
        trace('   Failed to instantiate module: ${moduleCls}');
      }
    }
    reorderModuleCache();

    trace("[MODULEHANDLER] Module cache loaded.");
  }

  public static function buildModuleCallbacks():Void
  {
    if (callbacksBuilt) return;
    callbacksBuilt = true;
    FlxG.signals.postStateSwitch.add(onStateSwitchComplete);
  }

  static function onStateSwitchComplete():Void
  {
    callEvent(new StateChangeScriptEvent(STATE_CHANGE_END, FlxG.state, true));
  }

  static function addToModuleCache(module:Module):Void
  {
    moduleCache.set(module.moduleId, module);
  }

  static function reorderModuleCache():Void
  {
    modulePriorityOrder = moduleCache.keys().array();

    modulePriorityOrder.sort(sortByPriority);
  }

  /**
   * Given two module IDs, sort them by priority.
   * @return 1 or -1 depending on which module has a higher priority.
   */
  static function sortByPriority(a:String, b:String):Int
  {
    var aModule:Null<Module> = getModule(a);
    var bModule:Null<Module> = getModule(b);

    if (aModule == null || bModule == null)
    {
      return 0;
    }
    if (aModule.priority != bModule.priority)
    {
      return aModule.priority - bModule.priority;
    }
    else
    {
      return SortUtil.alphabetically(a, b);
    }
  }

  public static function getModule(moduleId:String):Null<Module>
  {
    return moduleCache.get(moduleId);
  }

  public static function activateModule(moduleId:String):Void
  {
    var module:Null<Module> = getModule(moduleId);
    if (module != null)
    {
      module.active = true;
    }
  }

  public static function deactivateModule(moduleId:String):Void
  {
    var module:Null<Module> = getModule(moduleId);
    if (module != null)
    {
      module.active = false;
    }
  }

  /**
   * Clear the module cache, forcing all modules to call shutdown events.
   */
  public static function clearModuleCache():Void
  {
    if (moduleCache != null)
    {
      var event = new ScriptEvent(DESTROY, false);

      // Note: Ignore stopPropagation()
      for (key => value in moduleCache)
      {
        ScriptEventDispatcher.callEvent(value, event);
      }

      moduleCache.clear();
      modulePriorityOrder = [];
    }
  }

  public static function callEvent(event:ScriptEvent):Void
  {
    for (moduleId in modulePriorityOrder)
    {
      var module:Null<Module> = moduleCache.get(moduleId);
      // The module needs to be active to receive events.
      if (module != null && module.active)
      {
        if (module.state != null)
        {
          // Only call the event if the current state is what the module's state is.
          if (!isModuleStateActive(module.state))
          {
            continue;
          }
        }
        refreshPlayStateBackrefs(module);
        ScriptEventDispatcher.callEvent(module, event);
      }
    }
  }

  public static function callPlusStateEvent(event:ScriptEvent):Void
  {
    for (moduleId in modulePriorityOrder)
    {
      var module:Null<Module> = moduleCache.get(moduleId);
      if (module == null || !module.active || module.state == null) continue;
      if (!isModuleStateActive(module.state)) continue;

      refreshPlayStateBackrefs(module);
      ScriptEventDispatcher.callEvent(module, event);
    }
  }

  static function isModuleStateActive(state:Class<Dynamic>):Bool
  {
    if (Type.getClass(FlxG.state) == state || Type.getClass(FlxG.state?.subState) == state) return true;

    #if vslice
    if (isPlusStateAlias(state, Type.getClass(FlxG.state)) || isPlusStateAlias(state, Type.getClass(FlxG.state?.subState))) return true;
    #end

    // Plus can enter the VSlice PlayState through the official transition bridge.
    // During that handoff some module events can fire while FlxG.state still
    // reports the wrapper/loading state, so trust the official singleton too.
    if (state == funkin.play.PlayState && funkin.play.PlayState.instance != null) return true;

    return false;
  }

  #if vslice
  static function isPlusStateAlias(moduleState:Class<Dynamic>, activeState:Null<Class<Dynamic>>):Bool
  {
    if (activeState == null) return false;

    if (moduleState == funkin.ui.mainmenu.MainMenuState && activeState == states.MainMenuState) return true;
    if (moduleState == funkin.ui.freeplay.FreeplayState && (activeState == states.FreeplayState || activeState == states.FreeplayState_Psych)) return true;
    if (moduleState == funkin.ui.story.StoryMenuState && activeState == states.StoryMenuState) return true;

    return false;
  }
  #end

  static function refreshPlayStateBackrefs(module:Module):Void
  {
    if (module.state != funkin.play.PlayState || funkin.play.PlayState.instance == null) return;

    safeRefreshPlayStateField(module, 'playState', funkin.play.PlayState.instance);
    safeRefreshPlayStateField(module, 'stage', funkin.play.PlayState.instance.currentStage);
  }

  static function safeRefreshPlayStateField(module:Module, field:String, value:Dynamic):Void
  {
    // HScripted classes are not open Dynamic objects. Only refresh optional
    // backrefs when the script class actually declared the field.
    if (!Reflect.hasField(module, field)) return;

    try
    {
      Reflect.setField(module, field, value);
    }
    catch (_:Dynamic)
    {
      // Some Polymod script wrappers expose fields through the interpreter but
      // reject Reflect writes. The scripts can still read PlayState.instance.
    }
  }

  public static inline function callOnCreate():Void
  {
    callEvent(new ScriptEvent(CREATE, false));
  }
}

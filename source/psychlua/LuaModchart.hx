package psychlua;

import modchart.Manager;
import modchart.backend.core.ArrowData;
import modchart.backend.standalone.Adapter;
import modchart.engine.PlayField;
import modchart.engine.modifiers.list.PathModifier;
import modchart.engine.modifiers.list.PathModifier.PathNode;
import psychlua.FunkinLua;
import backend.Song;
import backend.Controls;
import flixel.tweens.FlxEase;
import flixel.input.keyboard.FlxKey;

using StringTools;

class LuaModchart
{
    static final __luaArrowPoint:FlxPoint = FlxPoint.get();
    static final __luaArrowData:ArrowData = {
        hitTime: 0,
        distance: 0,
        sourceTime: 0,
        lane: 0,
        player: 0,
        isTapArrow: false,
        straightHolds: false
    };

    public static function getRenderedStrumPosition(strum:FlxSprite, ?field:Dynamic = -1):Null<FlxPoint> {
        if (strum == null || Manager.instance == null || Adapter.instance == null)
            return null;

        final playfields = Manager.instance.playfields;
        if (playfields == null || playfields.length == 0)
            return null;

        final player = Adapter.instance.getPlayerFromArrow(strum);
        var targetField = resolveFieldIndex(field, -1);
        if (targetField < 0)
            targetField = playfields.length > 1 ? Std.int(Math.min(player, playfields.length - 1)) : 0;

        if (targetField < 0 || targetField >= playfields.length)
            return null;

        final playfield = playfields[targetField];
        if (playfield == null)
            return null;

        final lane = Adapter.instance.getLaneFromArrow(strum);
        final songPos = Adapter.instance.getSongPosition();
        var arrowTime = Adapter.instance.getTimeFromArrow(strum);
        var arrowDiff = arrowTime - songPos;
        final centered2 = playfield.getPercent('centered2', player);
        final isTapArrow = Adapter.instance.isTapNote(strum);

        if (isTapArrow) {
            arrowDiff += FlxG.height * 0.25 * centered2;
        } else {
            arrowTime = songPos + (FlxG.height * 0.25 * centered2);
            arrowDiff = arrowTime - songPos;
        }

        __luaArrowData.hitTime = arrowTime;
        __luaArrowData.distance = arrowDiff;
        __luaArrowData.sourceTime = Adapter.instance.getTimeFromArrow(strum);
        __luaArrowData.lane = lane;
        __luaArrowData.player = player;
        __luaArrowData.hitten = Adapter.instance.arrowHit(strum);
        __luaArrowData.isTapArrow = isTapArrow;

        final arrowPosition = new openfl.geom.Vector3D(
            Adapter.instance.getDefaultReceptorX(lane, player) + Manager.ARROW_SIZEDIV2,
            Adapter.instance.getDefaultReceptorY(lane, player) + Manager.ARROW_SIZEDIV2,
            0
        );
        final output = playfield.modifiers.getPath(arrowPosition, __luaArrowData);

        __luaArrowPoint.set(output.pos.x - Manager.ARROW_SIZEDIV2, output.pos.y - Manager.ARROW_SIZEDIV2);
        return __luaArrowPoint;
    }

    public static function implement(funk:FunkinLua) {
        var lua:State = funk.lua;
        
        // Add modifier
        Lua_helper.add_callback(lua, "addModifier", function(name:String, ?field:Dynamic = -1) {
            if (Manager.instance == null)
                return;

            if (isNamedPlayfield(field)) {
                final playfield = requireNamedPlayfield(field, 'addModifier');
                if (playfield != null)
                    playfield.addModifier(name);
                return;
            }

            Manager.instance.addModifier(name, resolveFieldIndex(field, -1));
        });
        
        // Set modifier percent
        Lua_helper.add_callback(lua, "setPercent", function(name:String, value:Float, ?player:Int = -1, ?field:Dynamic = -1) {
            if (Manager.instance == null)
                return;

            if (isNamedPlayfield(field)) {
                final playfield = requireNamedPlayfield(field, 'setPercent');
                if (playfield != null)
                    playfield.setPercent(name, value, player);
                return;
            }

            Manager.instance.setPercent(name, value, player, resolveFieldIndex(field, -1));
        });
        
        // Get modifier percent
        Lua_helper.add_callback(lua, "getPercent", function(name:String, ?player:Int = 0, ?field:Dynamic = 0):Float {
            if (Manager.instance == null)
                return 0.0;

            if (isNamedPlayfield(field)) {
                final playfield = requireNamedPlayfield(field, 'getPercent', false);
                return playfield != null ? playfield.getPercent(name, player) : 0.0;
            }

            return Manager.instance.getPercent(name, player, resolveFieldIndex(field, 0));
            return 0.0;
        });
        
        // Set modifier raw value
        Lua_helper.add_callback(lua, "setRawValue", function(name:String, value:Float, ?player:Int = -1, ?field:Dynamic = -1) {
            if (Manager.instance == null)
                return;

            if (isNamedPlayfield(field)) {
                final playfield = requireNamedPlayfield(field, 'setRawValue');
                if (playfield != null)
                    playfield.setRawValue(name, value, player);
                return;
            }

            Manager.instance.setRawValue(name, value, player, resolveFieldIndex(field, -1));
        });
        
        // Get modifier raw value
        Lua_helper.add_callback(lua, "getRawValue", function(name:String, ?player:Int = 0, ?field:Dynamic = 0):Float {
            if (Manager.instance == null)
                return 0.0;

            if (isNamedPlayfield(field)) {
                final playfield = requireNamedPlayfield(field, 'getRawValue', false);
                return playfield != null ? playfield.getRawValue(name, player) : 0.0;
            }

            return Manager.instance.getRawValue(name, player, resolveFieldIndex(field, 0));
            return 0.0;
        });
        
        // Set a value at a specific beat
        Lua_helper.add_callback(lua, "set", function(nameOrMods:Dynamic, beat:Float, ?value:Dynamic, ?player:Int = -1, ?field:Dynamic = -1) {
            if (Manager.instance == null)
                return;

            final namedPlayfield = isNamedPlayfield(field) ? requireNamedPlayfield(field, 'set') : null;
            
            // Check if first parameter is a table of mods
            if (Std.isOfType(nameOrMods, String)) {
                // Single mod: set('modname', beat, value, player, field)
                if (namedPlayfield != null)
                    namedPlayfield.set(cast nameOrMods, beat, cast value, player);
                else
                    Manager.instance.set(cast nameOrMods, beat, cast value, player, resolveFieldIndex(field, -1));
            } else {
                // Multiple mods: set({mod1=100, mod2=50}, beat, player, field)
                // In this case: value becomes player, player becomes field
                final mods:Dynamic = nameOrMods;
                final actualPlayer:Int = value != null ? cast value : -1;
                final actualField:Dynamic = player != null ? player : -1;
                
                for (modName in Reflect.fields(mods)) {
                    final modValue:Float = Reflect.field(mods, modName);
                    if (namedPlayfield != null)
                        namedPlayfield.set(modName, beat, modValue, actualPlayer);
                    else
                        Manager.instance.set(modName, beat, modValue, actualPlayer, resolveFieldIndex(actualField, -1));
                }
            }
        });
        
        // Ease a modifier
        Lua_helper.add_callback(lua, "ease", function(nameOrMods:Dynamic, beat:Float, length:Float, ?value:Dynamic, ?easeName:String, ?player:Int = -1, ?field:Dynamic = -1) {
            if (Manager.instance == null)
                return;

            final namedPlayfield = isNamedPlayfield(field) ? requireNamedPlayfield(field, 'ease') : null;
            
            // Check if first parameter is a table of mods
            if (Std.isOfType(nameOrMods, String)) {
                // Single mod: ease('modname', beat, length, value, ease, player, field)
                var easeFunc = getEaseFunction(easeName);
                if (namedPlayfield != null)
                    namedPlayfield.ease(cast nameOrMods, beat, length, cast value, easeFunc, player);
                else
                    Manager.instance.ease(cast nameOrMods, beat, length, cast value, easeFunc, player, resolveFieldIndex(field, -1));
            } else {
                // Multiple mods: ease({mod1=100, mod2=50}, beat, length, ease, player, field)
                // In this case: value becomes easeName, easeName becomes player, player becomes field
                final mods:Dynamic = nameOrMods;
                final actualEaseName:String = cast value;
                final actualPlayer:Int = easeName != null ? Std.parseInt(easeName) : -1;
                final actualField:Dynamic = player != null ? player : -1;
                
                var easeFunc = getEaseFunction(actualEaseName);
                for (modName in Reflect.fields(mods)) {
                    final modValue:Float = Reflect.field(mods, modName);
                    if (namedPlayfield != null)
                        namedPlayfield.ease(modName, beat, length, modValue, easeFunc, actualPlayer);
                    else
                        Manager.instance.ease(modName, beat, length, modValue, easeFunc, actualPlayer, resolveFieldIndex(actualField, -1));
                }
            }
        });
        
        // Add with easing
        Lua_helper.add_callback(lua, "add", function(nameOrMods:Dynamic, beat:Float, length:Float, ?value:Dynamic, ?easeName:String, ?player:Int = -1, ?field:Dynamic = -1) {
            if (Manager.instance == null)
                return;

            final namedPlayfield = isNamedPlayfield(field) ? requireNamedPlayfield(field, 'add') : null;
            
            // Check if first parameter is a table of mods
            if (Std.isOfType(nameOrMods, String)) {
                // Single mod: add('modname', beat, length, value, ease, player, field)
                var easeFunc = getEaseFunction(easeName);
                if (namedPlayfield != null)
                    namedPlayfield.add(cast nameOrMods, beat, length, cast value, easeFunc, player);
                else
                    Manager.instance.add(cast nameOrMods, beat, length, cast value, easeFunc, player, resolveFieldIndex(field, -1));
            } else {
                // Multiple mods: add({mod1=100, mod2=50}, beat, length, ease, player, field)
                // In this case: value becomes easeName, easeName becomes player, player becomes field
                final mods:Dynamic = nameOrMods;
                final actualEaseName:String = cast value;
                final actualPlayer:Int = easeName != null ? Std.parseInt(easeName) : -1;
                final actualField:Dynamic = player != null ? player : -1;
                
                var easeFunc = getEaseFunction(actualEaseName);
                for (modName in Reflect.fields(mods)) {
                    final modValue:Float = Reflect.field(mods, modName);
                    if (namedPlayfield != null)
                        namedPlayfield.add(modName, beat, length, modValue, easeFunc, actualPlayer);
                    else
                        Manager.instance.add(modName, beat, length, modValue, easeFunc, actualPlayer, resolveFieldIndex(actualField, -1));
                }
            }
        });
        
        // SetAdd helper
        Lua_helper.add_callback(lua, "setAdd", function(nameOrMods:Dynamic, beat:Float, ?value:Dynamic, ?player:Int = -1, ?field:Dynamic = -1) {
            if (Manager.instance == null)
                return;

            final namedPlayfield = isNamedPlayfield(field) ? requireNamedPlayfield(field, 'setAdd') : null;
            
            // Check if first parameter is a table of mods
            if (Std.isOfType(nameOrMods, String)) {
                // Single mod: setAdd('modname', beat, value, player, field)
                if (namedPlayfield != null)
                    namedPlayfield.setAdd(cast nameOrMods, beat, cast value, player);
                else
                    Manager.instance.setAdd(cast nameOrMods, beat, cast value, player, resolveFieldIndex(field, -1));
            } else {
                // Multiple mods: setAdd({mod1=100, mod2=50}, beat, player, field)
                // In this case: value becomes player, player becomes field
                final mods:Dynamic = nameOrMods;
                final actualPlayer:Int = value != null ? cast value : -1;
                final actualField:Dynamic = player != null ? player : -1;
                
                for (modName in Reflect.fields(mods)) {
                    final modValue:Float = Reflect.field(mods, modName);
                    if (namedPlayfield != null)
                        namedPlayfield.setAdd(modName, beat, modValue, actualPlayer);
                    else
                        Manager.instance.setAdd(modName, beat, modValue, actualPlayer, resolveFieldIndex(actualField, -1));
                }
            }
        });
        
        // Add new playfield
        Lua_helper.add_callback(lua, "addPlayfield", function(?nameOrBeat:Dynamic = null, ?beat:Null<Float>) {
            if (Manager.instance == null)
                return;

            var name:Null<String> = null;
            var targetBeat:Null<Float> = null;

            if (Std.isOfType(nameOrBeat, String))
                name = Std.string(nameOrBeat).trim();
            else if (nameOrBeat != null)
                targetBeat = toFloat(nameOrBeat, Math.NaN);

            if (beat != null)
                targetBeat = beat;

            if (targetBeat != null && Math.isNaN(targetBeat))
                targetBeat = null;

            Manager.instance.addPlayfield(name, targetBeat);
        });

        Lua_helper.add_callback(lua, "removePlayfield", function(fieldOrName:Dynamic, ?beat:Null<Float>) {
            if (Manager.instance == null || fieldOrName == null)
                return;

            final targetBeat:Null<Float> = beat;
            if (isNamedPlayfield(fieldOrName))
                Manager.instance.removeNamedPlayfield(Std.string(fieldOrName).trim(), targetBeat);
            else
                Manager.instance.removePlayfield(resolveFieldIndex(fieldOrName, -1), targetBeat);
        });
        
        // Create alias for a modifier
        Lua_helper.add_callback(lua, "alias", function(name:String, aliasName:String, field:Dynamic) {
            if (Manager.instance == null)
                return;

            if (isNamedPlayfield(field)) {
                final playfield = requireNamedPlayfield(field, 'alias');
                if (playfield != null)
                    playfield.alias(name, aliasName);
                return;
            }

            Manager.instance.alias(name, aliasName, resolveFieldIndex(field, -1));
        });
        
        // Useful constants
        Lua_helper.add_callback(lua, "getHoldSize", function():Float {
            return Manager.HOLD_SIZE;
        });
        
        Lua_helper.add_callback(lua, "getHoldSizeDiv2", function():Float {
            return Manager.HOLD_SIZEDIV2;
        });
        
        Lua_helper.add_callback(lua, "getArrowSize", function():Float {
            return Manager.ARROW_SIZE;
        });
        
        Lua_helper.add_callback(lua, "getArrowSizeDiv2", function():Float {
            return Manager.ARROW_SIZEDIV2;
        });
        
        // Callback event: execute a function on a specific beat
        Lua_helper.add_callback(lua, "callback", function(beat:Float, funcName:String, ?field:Dynamic = -1) {
            if (Manager.instance != null) {
                if (isNamedPlayfield(field)) {
                    final playfield = requireNamedPlayfield(field, 'callback');
                    if (playfield != null)
                        playfield.callback(beat, function(event) {
                            funk.call(funcName, []);
                        });
                } else {
                    Manager.instance.callback(beat, function(event) {
                        funk.call(funcName, []); // Do not pass the event object to Lua
                    }, resolveFieldIndex(field, -1));
                }
            }
        });
        
        // Schedule a callback to run once on a specific beat (alias for callback)
        Lua_helper.add_callback(lua, "scheduleCallback", function(beat:Float, funcName:String, ?field:Dynamic = -1) {
            if (Manager.instance != null) {
                if (isNamedPlayfield(field)) {
                    final playfield = requireNamedPlayfield(field, 'scheduleCallback');
                    if (playfield != null)
                        playfield.scheduleCallback(beat, function(event) {
                            funk.call(funcName, []);
                        });
                } else {
                    Manager.instance.scheduleCallback(beat, function(event) {
                        funk.call(funcName, []); // Do not pass the event object to Lua
                    }, resolveFieldIndex(field, -1));
                }
            }
        });
        
        // Repeater event: execute a function repeatedly for a duration
        Lua_helper.add_callback(lua, "repeater", function(beat:Float, length:Float, funcName:String, ?field:Dynamic = -1) {
            if (Manager.instance != null) {
                if (isNamedPlayfield(field)) {
                    final playfield = requireNamedPlayfield(field, 'repeater');
                    if (playfield != null)
                        playfield.repeater(beat, length, function(event) {
                            funk.call(funcName, []);
                        });
                } else {
                    Manager.instance.repeater(beat, length, function(event) {
                        funk.call(funcName, []); // Do not pass the event object to Lua
                    }, resolveFieldIndex(field, -1));
                }
            }
        });
        
        // Add scripted (custom) modifier
        Lua_helper.add_callback(lua, "addScriptedModifier", function(name:String, modifierInstance:Dynamic, ?field:Dynamic = -1) {
            if (Manager.instance != null && modifierInstance != null) {
                // `modifierInstance` must be an instance of `Modifier` created via Lua/HScript
                if (isNamedPlayfield(field)) {
                    final playfield = requireNamedPlayfield(field, 'addScriptedModifier');
                    if (playfield != null)
                        playfield.addScriptedModifier(name, modifierInstance);
                } else {
                    Manager.instance.addScriptedModifier(name, modifierInstance, resolveFieldIndex(field, -1));
                }
            }
        });
        
        // Create a node: bind inputs and outputs through a function
        Lua_helper.add_callback(lua, "node", function(inputs:Array<String>, outputs:Array<String>, funcName:String, ?field:Dynamic = -1) {
            if (Manager.instance != null) {
                final nodeFunc = function(curInput:Array<Float>, curOutput:Int):Array<Float> {
                    // Call the Lua function with the input values
                    var result:Dynamic = funk.call(funcName, [curInput]);
                    // Return result as an array of floats, or an array with `curOutput` if missing
                    if (result != null && Std.isOfType(result, Array)) {
                        return cast result;
                    }
                    return [curOutput]; // Default to an array containing `curOutput`
                };

                if (isNamedPlayfield(field)) {
                    final playfield = requireNamedPlayfield(field, 'node');
                    if (playfield != null)
                        playfield.node(inputs, outputs, nodeFunc);
                } else {
                    Manager.instance.node(inputs, outputs, nodeFunc, resolveFieldIndex(field, -1));
                }
            }
        });

		// PathModifier helpers (works for any modifier that extends PathModifier, e.g. arrowshape, luapath)
        Lua_helper.add_callback(lua, "setModifierPath", function(modName:String, nodes:Array<Dynamic>, ?field:Dynamic = 0, ?lane:Int = -1) {
			if (Manager.instance == null)
				return;
            final pf = resolvePlayfield(field, 0, 'setModifierPath');
			if (pf == null) {
				return;
			}

			final mod = pf.modifiers.modifiers.get(modName.toLowerCase());
			if (mod == null) {
				PlayState.instance.addTextToDebug('setModifierPath: modifier not found: ' + modName, 0xFFFF0000);
				return;
			}
			if (!Std.isOfType(mod, PathModifier)) {
				PlayState.instance.addTextToDebug('setModifierPath: modifier is not a PathModifier: ' + modName, 0xFFFF0000);
				return;
			}

			final parsed = parsePathNodes(nodes);
			if (lane >= 0) {
				// Set path for specific lane
				cast(mod, PathModifier).loadPathForLane(parsed, lane);
			} else {
				// Set global path (affects all lanes without specific paths)
				cast(mod, PathModifier).loadPath(parsed);
			}
		});

        Lua_helper.add_callback(lua, "setModifierPathOffset", function(modName:String, x:Float, y:Float, ?z:Float = 0, ?field:Dynamic = 0) {
			if (Manager.instance == null)
				return;
            final pf = resolvePlayfield(field, 0, 'setModifierPathOffset');
	 		if (pf == null) {
				return;
			}

			final mod = pf.modifiers.modifiers.get(modName.toLowerCase());
			if (mod == null || !Std.isOfType(mod, PathModifier)) {
				PlayState.instance.addTextToDebug('setModifierPathOffset: PathModifier not found: ' + modName, 0xFFFF0000);
				return;
			}

			cast(mod, PathModifier).pathOffset.setTo(x, y, z);
		});

        Lua_helper.add_callback(lua, "setModifierPathBound", function(modName:String, bound:Float, ?field:Dynamic = 0) {
			if (Manager.instance == null)
				return;
            final pf = resolvePlayfield(field, 0, 'setModifierPathBound');
			if (pf == null) {
				return;
			}

			final mod = pf.modifiers.modifiers.get(modName.toLowerCase());
			if (mod == null || !Std.isOfType(mod, PathModifier)) {
				PlayState.instance.addTextToDebug('setModifierPathBound: PathModifier not found: ' + modName, 0xFFFF0000);
				return;
			}

			cast(mod, PathModifier).setPathBound(bound);
		});

        Lua_helper.add_callback(lua, "changeControls", function(bindings:Dynamic) {
            if (PlayState.instance == null || Controls.instance == null || bindings == null)
                return;

            for (fieldName in Reflect.fields(bindings)) {
                final controlName = normalizeGameplayControlName(fieldName);
                if (controlName == null) {
                    PlayState.instance.addTextToDebug('changeControls: invalid control "' + fieldName + '"', 0xFFFF0000);
                    continue;
                }

                final parsedKeys = parseLuaKeyList(Reflect.field(bindings, fieldName), fieldName);
                if (parsedKeys == null)
                    continue;

                if (parsedKeys.length <= 0)
                    Controls.instance.clearTemporaryKeyboardBind(controlName);
                else
                    Controls.instance.setTemporaryKeyboardBind(controlName, parsedKeys);
            }
        });

        Lua_helper.add_callback(lua, "restoreControls", function() {
            if (Controls.instance != null)
                Controls.instance.clearTemporaryGameplayBinds();
        });

        Lua_helper.add_callback(lua, "getGameplayControls", function():Dynamic {
            final result:Dynamic = {};
            if (Controls.instance == null)
                return result;

            for (controlName in Controls.GAMEPLAY_KEY_NAMES) {
                final keys = Controls.instance.getKeyboardBind(controlName);
                final keyNames:Array<String> = [];
                if (keys != null)
                    for (key in keys)
                        keyNames.push(Std.string(key));
                Reflect.setField(result, controlName, keyNames);
            }

            return result;
        });
        
        // ===== "NOW" VARIANTS FOR USE IN CALLBACKS =====
        // These functions automatically calculate the current beat,
        // allowing you to use modcharts from onBeatHit/onStepHit/onUpdatePost
        
        // Set modifier percent immediately (current beat)
        Lua_helper.add_callback(lua, "setNow", function(nameOrMods:Dynamic, ?value:Dynamic, ?player:Int = -1, ?field:Dynamic = -1) {
            if (Manager.instance == null)
                return;
            
            var currentBeat:Float = Conductor.songPosition / Conductor.crochet;
            
            // Check if first parameter is a table of mods
            if (Std.isOfType(nameOrMods, String)) {
                // Single mod: setNow('modname', value, player, field)
                if (isNamedPlayfield(field)) {
                    final playfield = requireNamedPlayfield(field, 'setNow');
                    if (playfield != null)
                        playfield.set(cast nameOrMods, currentBeat, cast value, player);
                } else {
                    Manager.instance.set(cast nameOrMods, currentBeat, cast value, player, resolveFieldIndex(field, -1));
                }
            } else {
                // Multiple mods: setNow({mod1=100, mod2=50}, player, field)
                final mods:Dynamic = nameOrMods;
                final actualPlayer:Int = value != null ? cast value : -1;
                final actualField:Dynamic = player != null ? player : -1;
                
                for (modName in Reflect.fields(mods)) {
                    final modValue:Float = Reflect.field(mods, modName);
                    if (isNamedPlayfield(actualField)) {
                        final playfield = requireNamedPlayfield(actualField, 'setNow');
                        if (playfield != null)
                            playfield.set(modName, currentBeat, modValue, actualPlayer);
                    } else {
                        Manager.instance.set(modName, currentBeat, modValue, actualPlayer, resolveFieldIndex(actualField, -1));
                    }
                }
            }
        });
        
        // Ease modifier from current beat
        Lua_helper.add_callback(lua, "easeNow", function(nameOrMods:Dynamic, length:Float, ?value:Dynamic, ?easeName:String, ?player:Int = -1, ?field:Dynamic = -1) {
            if (Manager.instance == null)
                return;
            
            var currentBeat:Float = Conductor.songPosition / Conductor.crochet;
            
            // Check if first parameter is a table of mods
            if (Std.isOfType(nameOrMods, String)) {
                // Single mod: easeNow('modname', length, value, ease, player, field)
                var easeFunc = getEaseFunction(easeName);
                if (isNamedPlayfield(field)) {
                    final playfield = requireNamedPlayfield(field, 'easeNow');
                    if (playfield != null)
                        playfield.ease(cast nameOrMods, currentBeat, length, cast value, easeFunc, player);
                } else {
                    Manager.instance.ease(cast nameOrMods, currentBeat, length, cast value, easeFunc, player, resolveFieldIndex(field, -1));
                }
            } else {
                // Multiple mods: easeNow({mod1=100, mod2=50}, length, ease, player, field)
                final mods:Dynamic = nameOrMods;
                final actualEaseName:String = cast value;
                final actualPlayer:Int = easeName != null ? Std.parseInt(easeName) : -1;
                final actualField:Dynamic = player != null ? player : -1;
                
                var easeFunc = getEaseFunction(actualEaseName);
                for (modName in Reflect.fields(mods)) {
                    final modValue:Float = Reflect.field(mods, modName);
                    if (isNamedPlayfield(actualField)) {
                        final playfield = requireNamedPlayfield(actualField, 'easeNow');
                        if (playfield != null)
                            playfield.ease(modName, currentBeat, length, modValue, easeFunc, actualPlayer);
                    } else {
                        Manager.instance.ease(modName, currentBeat, length, modValue, easeFunc, actualPlayer, resolveFieldIndex(actualField, -1));
                    }
                }
            }
        });
        
        // Add modifier with easing from current beat
        Lua_helper.add_callback(lua, "addNow", function(nameOrMods:Dynamic, length:Float, ?value:Dynamic, ?easeName:String, ?player:Int = -1, ?field:Dynamic = -1) {
            if (Manager.instance == null)
                return;
            
            var currentBeat:Float = Conductor.songPosition / Conductor.crochet;
            
            // Check if first parameter is a table of mods
            if (Std.isOfType(nameOrMods, String)) {
                // Single mod: addNow('modname', length, value, ease, player, field)
                var easeFunc = getEaseFunction(easeName);
                if (isNamedPlayfield(field)) {
                    final playfield = requireNamedPlayfield(field, 'addNow');
                    if (playfield != null)
                        playfield.add(cast nameOrMods, currentBeat, length, cast value, easeFunc, player);
                } else {
                    Manager.instance.add(cast nameOrMods, currentBeat, length, cast value, easeFunc, player, resolveFieldIndex(field, -1));
                }
            } else {
                // Multiple mods: addNow({mod1=100, mod2=50}, length, ease, player, field)
                final mods:Dynamic = nameOrMods;
                final actualEaseName:String = cast value;
                final actualPlayer:Int = easeName != null ? Std.parseInt(easeName) : -1;
                final actualField:Dynamic = player != null ? player : -1;
                
                var easeFunc = getEaseFunction(actualEaseName);
                for (modName in Reflect.fields(mods)) {
                    final modValue:Float = Reflect.field(mods, modName);
                    if (isNamedPlayfield(actualField)) {
                        final playfield = requireNamedPlayfield(actualField, 'addNow');
                        if (playfield != null)
                            playfield.add(modName, currentBeat, length, modValue, easeFunc, actualPlayer);
                    } else {
                        Manager.instance.add(modName, currentBeat, length, modValue, easeFunc, actualPlayer, resolveFieldIndex(actualField, -1));
                    }
                }
            }
        });
        
        // SetAdd helper from current beat
        Lua_helper.add_callback(lua, "setAddNow", function(nameOrMods:Dynamic, ?value:Dynamic, ?player:Int = -1, ?field:Dynamic = -1) {
            if (Manager.instance == null)
                return;
            
            var currentBeat:Float = Conductor.songPosition / Conductor.crochet;
            
            // Check if first parameter is a table of mods
            if (Std.isOfType(nameOrMods, String)) {
                // Single mod: setAddNow('modname', value, player, field)
                if (isNamedPlayfield(field)) {
                    final playfield = requireNamedPlayfield(field, 'setAddNow');
                    if (playfield != null)
                        playfield.setAdd(cast nameOrMods, currentBeat, cast value, player);
                } else {
                    Manager.instance.setAdd(cast nameOrMods, currentBeat, cast value, player, resolveFieldIndex(field, -1));
                }
            } else {
                // Multiple mods: setAddNow({mod1=100, mod2=50}, player, field)
                final mods:Dynamic = nameOrMods;
                final actualPlayer:Int = value != null ? cast value : -1;
                final actualField:Dynamic = player != null ? player : -1;
                
                for (modName in Reflect.fields(mods)) {
                    final modValue:Float = Reflect.field(mods, modName);
                    if (isNamedPlayfield(actualField)) {
                        final playfield = requireNamedPlayfield(actualField, 'setAddNow');
                        if (playfield != null)
                            playfield.setAdd(modName, currentBeat, modValue, actualPlayer);
                    } else {
                        Manager.instance.setAdd(modName, currentBeat, modValue, actualPlayer, resolveFieldIndex(actualField, -1));
                    }
                }
            }
        });
        
        // Inspired by Troll Engine's forNoteInChart =P
        Lua_helper.add_callback(lua, "getChartNotes", function(chartName:String, ?songName:String):Dynamic {
            if (songName == null || songName.length == 0)
                songName = Song.loadedSongName;

            trace('Looking for chart="$chartName" song="$songName"');

            var swagSong = Song.getChart(chartName, songName);
            if (swagSong == null) {
                PlayState.instance.addTextToDebug('ERROR: chart "$chartName" not found in song "$songName"', 0xFFFF0000);
                return null;
            }

            trace('Chart found, sections=${swagSong.notes != null ? swagSong.notes.length : 0}');

            // Build a 1-indexed Lua-compatible array of note tables
            var result:Array<Dynamic> = [];
            if (swagSong.notes != null) {
                for (section in swagSong.notes) {
                    if (section == null || section.sectionNotes == null) continue;
                    for (noteData in section.sectionNotes) {
                        // noteData[0]=time(ms), noteData[1]=column/direction, noteData[2]=hold length
                        var time:Float = noteData[0];
                        var rawCol:Int = Std.int(noteData[1]);
                        var type:Int   = rawCol % 4;
                        var step:Float = Conductor.getStep(time);
                        result.push({
                            step: step,
                            type: type,
                            time: time
                        });
                    }
                }
            }

            // Sort ascending by step so the caller can just iterate in order
            result.sort(function(a, b) return a.step < b.step ? -1 : (a.step > b.step ? 1 : 0));

            trace('"$chartName" total notes=${result.length}'
                + (result.length > 0 ? ' | first: step=${result[0].step} type=${result[0].type} time=${result[0].time}ms' : ''));

            return result;
        });

        // Get current beat from Conductor
        Lua_helper.add_callback(lua, "getCurrentBeat", function():Float {
            return Conductor.songPosition / Conductor.crochet;
        });
        
        // Get current step from Conductor
        Lua_helper.add_callback(lua, "getCurrentStep", function():Float {
            return Conductor.songPosition / Conductor.stepCrochet;
        });
        
        // Get song position in milliseconds
        Lua_helper.add_callback(lua, "getSongPosition", function():Float {
            return Conductor.songPosition;
        });
        
        // Get current BPM
        Lua_helper.add_callback(lua, "getBPM", function():Float {
            return Conductor.bpm;
        });
        
        // Get player/playfield count
        Lua_helper.add_callback(lua, "getPlayerCount", function():Int {
            return Adapter.instance.getPlayerCount();
        });
        
        // Set hold subdivisions
        Lua_helper.add_callback(lua, "setHoldSubdivisions", function(value:Int) {
            if (Adapter.instance != null && Std.isOfType(Adapter.instance, modchart.backend.standalone.adapters.psych.Psych)) {
                cast(Adapter.instance, modchart.backend.standalone.adapters.psych.Psych).setHoldSubdivisions(value);
            }
        });
        
        // Get hold subdivisions
        Lua_helper.add_callback(lua, "getHoldSubdivisions", function():Int {
            if (Adapter.instance != null) {
                return Adapter.instance.getHoldSubdivisions(null);
            }
            return 0;
        });
    }
    
    // Helper: convert easing name to function
    private static function getEaseFunction(easeName:String) {
        return LuaUtils.getTweenEaseByString(easeName);
    }

    private static function isNamedPlayfield(field:Dynamic):Bool {
        return field != null && Std.isOfType(field, String) && Std.string(field).trim().length > 0 && Std.parseInt(Std.string(field).trim()) == null;
    }

    private static function resolveFieldIndex(field:Dynamic, defaultField:Int = -1):Int {
        if (field == null)
            return defaultField;
        if (Std.isOfType(field, Int))
            return cast field;
        if (Std.isOfType(field, Float))
            return Std.int(cast field);
        if (Std.isOfType(field, String)) {
            final trimmed = Std.string(field).trim();
            if (trimmed.length <= 0)
                return defaultField;

            final parsed = Std.parseInt(trimmed);
            return parsed != null ? parsed : defaultField;
        }
        return defaultField;
    }

    private static function requireNamedPlayfield(field:Dynamic, context:String, reportMissing:Bool = true):Null<PlayField> {
        if (Manager.instance == null || !isNamedPlayfield(field))
            return null;

        final name = Std.string(field).trim();
        final playfield = Manager.instance.getNamedPlayfield(name);
        if (playfield == null && reportMissing && PlayState.instance != null)
            PlayState.instance.addTextToDebug(context + ': playfield not found: ' + name, 0xFFFF0000);
        return playfield;
    }

    private static function resolvePlayfield(field:Dynamic, defaultField:Int, context:String):Null<PlayField> {
        if (Manager.instance == null)
            return null;

        if (isNamedPlayfield(field))
            return requireNamedPlayfield(field, context);

        final fieldIndex = resolveFieldIndex(field, defaultField);
        if (fieldIndex < 0 || fieldIndex >= Manager.instance.playfields.length) {
            if (PlayState.instance != null)
                PlayState.instance.addTextToDebug(context + ': invalid playfield index: ' + fieldIndex, 0xFFFF0000);
            return null;
        }

        final playfield = Manager.instance.playfields[fieldIndex];
        if (playfield == null && PlayState.instance != null)
            PlayState.instance.addTextToDebug(context + ': removed playfield index: ' + fieldIndex, 0xFFFF0000);
        return playfield;
    }

    private static inline function toFloat(value:Dynamic, defaultValue:Float = 0):Float {
        if (value == null)
            return defaultValue;
        if (Std.isOfType(value, Float) || Std.isOfType(value, Int))
            return value;
        final f = Std.parseFloat(Std.string(value));
        return Math.isNaN(f) ? defaultValue : f;
    }

    private static function normalizeGameplayControlName(value:String):Null<String> {
        if (value == null)
            return null;

        switch (value.toLowerCase()) {
            case 'left', 'noteleft', 'note_left':
                return 'note_left';
            case 'down', 'notedown', 'note_down':
                return 'note_down';
            case 'up', 'noteup', 'note_up':
                return 'note_up';
            case 'right', 'noteright', 'note_right':
                return 'note_right';
            default:
                return null;
        }
    }

    private static function parseLuaKeyList(rawValue:Dynamic, fieldName:String):Null<Array<FlxKey>> {
        if (rawValue == null)
            return [];

        final values:Array<Dynamic> = Std.isOfType(rawValue, Array) ? cast rawValue : [rawValue];
        final parsed:Array<FlxKey> = [];

        for (value in values) {
            if (value == null)
                continue;

            final text = Std.string(value).trim();
            if (text.length <= 0)
                continue;

            final key = FlxKey.fromString(text.toUpperCase());
            if (key == NONE) {
                if (PlayState.instance != null)
                    PlayState.instance.addTextToDebug('changeControls: invalid key "' + text + '" for ' + fieldName, 0xFFFF0000);
                return null;
            }

            if (!parsed.contains(key))
                parsed.push(key);
        }

        return parsed;
    }

    private static function parsePathNodes(nodes:Array<Dynamic>):Array<PathNode> {
        final out:Array<PathNode> = [];
        if (nodes == null)
            return out;

        for (node in nodes) {
            if (node == null)
                continue;

            var x = 0.0;
            var y = 0.0;
            var z = 0.0;

            if (Std.isOfType(node, Array)) {
                final arr:Array<Dynamic> = cast node;
                // Try both 0-based and 1-based indexing (Lua tables can vary depending on bridge)
                x = toFloat(arr.length > 0 ? arr[0] : null, 0);
                y = toFloat(arr.length > 1 ? arr[1] : null, 0);
                z = toFloat(arr.length > 2 ? arr[2] : null, 0);
                if (x == 0 && y == 0 && z == 0 && arr.length >= 4) {
                    x = toFloat(arr[1], 0);
                    y = toFloat(arr[2], 0);
                    z = toFloat(arr[3], 0);
                }
            } else {
                x = toFloat(Reflect.field(node, 'x'), 0);
                y = toFloat(Reflect.field(node, 'y'), 0);
                z = toFloat(Reflect.field(node, 'z'), 0);
            }

            out.push({x: x, y: y, z: z});
        }
        return out;
    }
}
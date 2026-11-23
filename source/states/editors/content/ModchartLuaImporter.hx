package states.editors.content;

import states.editors.content.ModchartTimeline.ModchartTimelineEvent;

/** Executes scheduling Lua in an isolated VM; loops and arithmetic are preserved. */
class ModchartLuaImporter
{
	static inline function tr(key:String, fallback:String):String
		return Language.getPhrase('editors.modchart.' + key, fallback);

	public static function parse(source:String):ModchartTimeline
	{
		#if LUA_ALLOWED
		var result = new ModchartTimeline();
		var lua = LuaL.newstate();
		LuaL.openlibs(lua);
		var callbackNames = ['__editorEvent', 'addModifier', '__editorField', '__editorScene', '__editorWarning', '__editorSetting'];
		var previousCallbacks:Map<String, Dynamic> = [];
		for (name in callbackNames) if (Lua_helper.callbacks.exists(name)) previousCallbacks.set(name, Lua_helper.callbacks.get(name));
		function dispose():Void {
			for (name in callbackNames) {
				@:privateAccess var key = Lua_helper.callbackKey(lua, name);
				Lua_helper.callbacksByState.remove(key);
				if (previousCallbacks.exists(name)) Lua_helper.callbacks.set(name, previousCallbacks.get(name));
				else Lua_helper.callbacks.remove(name);
			}
			Lua.close(lua);
		}
		Lua_helper.add_callback(lua, '__editorEvent', function(kind:String, mod:String, beat:Float, length:Float,
			value:Float, ease:String, player:Int, field:Int) {
			if (result.events.length >= 50000) throw tr('event_limit', 'Too many events (maximum 50000)');
			var event:ModchartTimelineEvent = {kind: kind, mod: mod, beat: beat, length: length, value: value,
				ease: ease, player: player, field: field};
			result.validate(event);
			result.events.push(event);
		});
		Lua_helper.add_callback(lua, 'addModifier', function(name:String, ?field:Dynamic = -1) {
			if (field != null && field != -1)
			{
				var warning = tr('modifier_field_warning', 'Field-specific modifier declaration loaded globally: ') + name;
				if (!result.warnings.contains(warning)) result.warnings.push(warning);
			}
			if (!result.modifiers.contains(name)) result.modifiers.push(name);
		});
		Lua_helper.add_callback(lua, '__editorField', function() {
			if (++result.fieldCount > 16) throw tr('field_limit', 'Maximum 16 playfields');
		});
		Lua_helper.add_callback(lua, '__editorScene', function(kind:String, phase:String, tag:String,
			?a:Dynamic, ?b:Dynamic, ?c:Dynamic, ?d:Dynamic, ?e:Dynamic, ?f:Dynamic) {
			if (result.scene.length > 5000) throw tr('scene_limit', 'Too many scene operations');
			result.scene.push({kind: kind, phase: phase, args: [tag, a, b, c, d, e, f]});
		});
		Lua_helper.add_callback(lua, '__editorWarning', function(message:String) {
			if (!result.warnings.contains(message)) result.warnings.push(message);
		});
		Lua_helper.add_callback(lua, '__editorSetting', function(name:String, value:Dynamic) {
			if (['holdSubdivisions', 'renderArrowPaths', 'styledArrowPaths', 'arrowPathBoundary'].contains(name))
				Reflect.setField(result.renderer, name, value);
		});
		// No filesystem, process, native modules, or unbounded loops during import.
		var prelude = '
local hook = debug.sethook
local ticks = 0
hook(function() ticks = ticks + 1; if ticks > 1000 then error("Lua instruction limit exceeded") end end, "", 10000)
if jit then jit.off() end
io=nil; os=nil; package=nil; require=nil; dofile=nil; loadfile=nil; debug=nil; jit=nil; ffi=nil
function set(name, beat, value, player, field)
  if type(name)=="table" then for n,v in pairs(name) do set(n,beat,v,value,player) end; return end
  if type(field)=="string" then __editorWarning("Named playfield event ignored in preview: "..field); return end
  __editorEvent("set",name,beat,0,value,"linear",player or -1,field or -1)
end
function ease(name, beat, length, value, easing, player, field)
  if type(name)=="table" then for n,v in pairs(name) do ease(n,beat,length,v,value,easing,player) end; return end
  if type(field)=="string" then __editorWarning("Named playfield event ignored in preview: "..field); return end
  __editorEvent("ease",name,beat,length,value or 1,easing or "linear",player or -1,field or -1)
end
function add(name, beat, length, value, easing, player, field)
  if type(name)=="table" then for n,v in pairs(name) do add(n,beat,length,v,value,easing,player) end; return end
  if type(field)=="string" then __editorWarning("Named playfield event ignored in preview: "..field); return end
  __editorEvent("add",name,beat,length,value or 1,easing or "linear",player or -1,field or -1)
end
function setPercent(name,value,player,field) set(name,-5,value,player,field) end
function getPercent() return 0 end
function setRawValue(name,value,player,field)
 __editorWarning("Raw modifier values are previewed as timeline values")
 set(name,-5,value,player,field)
end
setValue=setRawValue
function getRawValue() return 0 end
getValue=getRawValue
function setNow(name,value,player,field)
 if type(name)=="table" then for n,v in pairs(name) do set(n,-5,v,value,player) end
 else set(name,-5,value,player,field) end
end
function easeNow(name,length,value,easing,player,field) ease(name,-5,length,value,easing,player,field) end
function addNow(name,length,value,easing,player,field) add(name,-5,length,value,easing,player,field) end
function queueSet(beat,name,value,player,field) set(name,beat,value,player,field) end
function queueEase(beat,last,name,value,easing,player,startValue,field)
 if startValue~=nil then set(name,beat,startValue,player,field) end
 ease(name,beat,last-beat,value,easing,player,field)
end
queueSetP=queueSet; queueEaseP=queueEase
function addPlayfield(name,beat)
 if name~=nil or beat~=nil then __editorWarning("Named or scheduled playfield ignored in preview: "..tostring(name)); return end
 __editorField()
end
function createModifier(name,options)
 __editorWarning("Custom modifier ignored in preview: "..tostring(name))
end
function callback(beat,name,field)
 __editorWarning("Lua callback ignored in preview: "..tostring(name))
end
function queueFuncOnce(beat,name,field) callback(beat,name,field) end
function queueFunc(beat,last,name,field) callback(beat,name,field) end
manager={}
local function method(fn)
 return function(first,...)
   if first==manager then return fn(...) end
   return fn(first,...)
 end
end
manager.set=method(set); manager.ease=method(ease); manager.add=method(add)
manager.addModifier=method(addModifier); manager.setPercent=method(setPercent)
manager.getPercent=method(getPercent); manager.setRawValue=method(setRawValue); manager.getRawValue=method(getRawValue)
manager.setValue=method(setValue); manager.getValue=method(getValue)
manager.queueSet=method(queueSet); manager.queueEase=method(queueEase)
manager.addPlayfield=method(addPlayfield)
manager.setNow=method(setNow); manager.easeNow=method(easeNow); manager.addNow=method(addNow)
Manager=manager; modchart=manager
local phase="create"
function __editorSetPhase(value) phase=value end
local function scene(kind,tag,...) __editorScene(kind,phase,tag,...) end
function makeLuaSprite(tag,image,x,y) scene("makeLuaSprite",tag,image or "",x or 0,y or 0) end
function makeAnimatedLuaSprite(tag,image,x,y) scene("makeAnimatedLuaSprite",tag,image or "",x or 0,y or 0) end
function makeLuaText(tag,text,width,x,y) scene("makeLuaText",tag,text or "",width or 0,x or 0,y or 0) end
function addLuaText(tag) scene("addLuaText",tag,true) end
function setTextString(tag,text) scene("setProperty",tag..".text",text) end
function setTextSize(tag,size) scene("setTextSize",tag,size) end
function setTextColor(tag,color) scene("setTextColor",tag,color) end
function setTextAlignment(tag,alignment) scene("setTextAlignment",tag,alignment) end
function makeGraphic(tag,w,h,color) scene("makeGraphic",tag,w,h,color or "FFFFFF") end
function setScrollFactor(tag,x,y) scene("setScrollFactor",tag,x,y) end
function scaleObject(tag,x,y) scene("scaleObject",tag,x,y) end
function screenCenter(tag,axes) scene("screenCenter",tag,axes or "xy") end
function setObjectCamera(tag,camera) scene("setObjectCamera",tag,camera) end
function setObjectOrder(tag,order) scene("setObjectOrder",tag,order) end
function addLuaSprite(tag,front) scene("addLuaSprite",tag,front or false) end
function removeLuaSprite(tag) scene("removeLuaSprite",tag) end
local editorProperties={downscroll=false,middlescroll=false}
local editorLengths={
 ["strumLineNotes.length"]=8,["playerStrums.length"]=4,["opponentStrums.length"]=4,
 ["notes.length"]=0,["unspawnNotes.length"]=0
}
function setProperty(path,value) editorProperties[path]=value; scene("setProperty",path,value) end
function getProperty(path)
 if editorProperties[path]~=nil then return editorProperties[path] end
 if editorLengths[path]~=nil then return editorLengths[path] end
 __editorWarning("getProperty previewed with default 0: "..tostring(path))
 return 0
end
function setPropertyFromGroup(group,index,key,value) scene("setPropertyFromGroup",group,index,key,value) end
function getPropertyFromGroup(group,index,key)
 __editorWarning("getPropertyFromGroup previewed with default 0: "..tostring(group).."."..tostring(key))
 return 0
end
function setBlendMode(tag,mode) scene("setBlendMode",tag,mode) end
function addAnimationByPrefix(tag,name,prefix,fps,loop) scene("addAnimationByPrefix",tag,name,prefix,fps or 24,loop or false) end
function addAnimationByIndices(tag,name,prefix,indices,fps,loop) scene("addAnimationByIndices",tag,name,prefix,indices,fps or 24,loop or false) end
function playAnim(tag,name) scene("playAnim",tag,name) end
objectPlayAnimation=playAnim
function doTweenAlpha(tag,target,value,duration,easing) scene("doTweenAlpha",tag,target,value,duration,easing or "linear") end
function doTweenX(tag,target,value,duration,easing) scene("doTweenX",tag,target,value,duration,easing or "linear") end
function doTweenY(tag,target,value,duration,easing) scene("doTweenY",tag,target,value,duration,easing or "linear") end
function doTweenAngle(tag,target,value,duration,easing) scene("doTweenAngle",tag,target,value,duration,easing or "linear") end
function setHoldSubdivisions(value) __editorSetting("holdSubdivisions",value) end
function configureModchartRenderer(config) for name,value in pairs(config) do __editorSetting(name,value) end end
function setArrowPathConfig(render,styled,boundary) configureModchartRenderer({renderArrowPaths=render,styledArrowPaths=styled,arrowPathBoundary=boundary}) end
function setModAutor() end
setModAuthor=setModAutor
function playLuaVideoSprite() __editorWarning("Videos are not loaded in the editor preview") end
function setLuaVideoVolume() end
function getPlayerCount() return 2 end
function getKeyCount() return 4 end
function getCurrentBeat() return -5 end
function getCurrentStep() return -20 end
function getSongPosition() return 0 end
function getBPM() return 120 end
screenWidth=1280; screenHeight=720; curBeat=-5; curStep=-20; songPosition=0; crochet=500; stepCrochet=125; bpm=120
for name,fn in pairs(math) do if _G[name]==nil then _G[name]=fn end end
';
		prelude = prelude.replace('"Lua instruction limit exceeded"', haxe.Json.stringify(tr('instruction_limit', 'Lua instruction limit exceeded')))
			.replace('"Only immediate numeric playfields can be imported"', haxe.Json.stringify(tr('numeric_fields', 'Only immediate numeric playfields can be imported')));
		prelude = prelude.replace("\"Videos are not loaded in the editor preview\"", haxe.Json.stringify(tr('videos_warning', "Videos are not loaded in the editor preview")));
		try
		{
			function execute(code:String):Void {
				if (LuaL.dostring(lua, code) != 0) {
					// Explicit String conversion is required: throwing ConstCharStar
					// directly becomes a boolean in hxcpp and hides the Lua error.
					var message:String = Lua.tostring(lua, -1); throw message;
				}
			}
			execute(prelude);
			var normalizedSource = source;
			// LuaJIT 5.1 treats a UTF-8 BOM as source code and may report the next
			// valid statement (often a `for`) as the syntax error.
			if (normalizedSource.length > 0 && normalizedSource.charCodeAt(0) == 0xFEFF)
				normalizedSource = normalizedSource.substr(1);
			execute(normalizedSource);
			var hooks = '
if onCreate then onCreate() end
if onCreatePost then onCreatePost() end
if onInitModchart then onInitModchart() end
__editorSetPhase("start")
if onSongStart then onSongStart() end
if onUpdate or onUpdatePost or onStepHit or onBeatHit then
 __editorWarning("Dynamic update/beat/step callbacks are not executed in the preview")
end
';
			hooks = hooks.replace("\"Dynamic update/beat/step callbacks are not executed in the preview\"", haxe.Json.stringify(tr('dynamic_warning', "Dynamic update/beat/step callbacks are not executed in the preview")));
			execute(hooks);
			dispose();
		}
		catch (error:Dynamic) { dispose(); throw error; }
		result.sort();
		return result;
		#else
		throw tr('lua_required', 'Lua import requires a build with LUA_ALLOWED');
		#end
	}
}

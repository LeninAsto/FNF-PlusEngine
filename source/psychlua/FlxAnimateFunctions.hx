package psychlua;

import openfl.utils.Assets;

#if (LUA_ALLOWED && flxanimate)
class FlxAnimateFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua:State = funk.lua;
		Lua_helper.add_callback(lua, "makeFlxAnimateSprite", function(tag:String, ?x:Float = 0, ?y:Float = 0, ?loadFolder:String = null) {
			tag = tag.replace('.', '');
			var lastSprite = MusicBeatState.getVariables().get(tag);
			if(lastSprite != null)
			{
				MusicBeatState.getVariables().remove(tag);
				lastSprite.kill();
				PlayState.instance.remove(lastSprite);
				lastSprite.destroy();
			}

			var mySprite:ModchartAnimateSprite = new ModchartAnimateSprite(x, y);
			mySprite.luaTag = tag;
			if(loadFolder != null) Paths.loadAnimateAtlas(mySprite, loadFolder);
			MusicBeatState.getVariables().set(tag, mySprite);
			mySprite.active = true;
		});

		Lua_helper.add_callback(lua, "loadAnimateAtlas", function(tag:String, folderOrImg:String, ?spriteJson:String = null, ?animationJson:String = null) {
			var obj:Dynamic = MusicBeatState.getVariables().get(tag);
			if(obj != null && Std.isOfType(obj, FlxAnimate))
			{
				var spr:FlxAnimate = cast obj;
				Paths.loadAnimateAtlas(spr, folderOrImg, spriteJson, animationJson);
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "setFlxAnimateAutoDeactivate", function(tag:String, ?enabled:Bool = true, ?destroyOnFinish:Bool = false) {
			var obj:Dynamic = MusicBeatState.getVariables().get(tag);
			if(obj != null && Std.isOfType(obj, ModchartAnimateSprite))
			{
				var spr:ModchartAnimateSprite = cast obj;
				spr.autoDeactivateOnFinish = enabled;
				spr.destroyOnFinish = destroyOnFinish;
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "deactivateFlxAnimateSprite", function(tag:String, ?hide:Bool = true) {
			var obj:Dynamic = MusicBeatState.getVariables().get(tag);
			if(obj != null && Std.isOfType(obj, FlxAnimate))
			{
				var spr:FlxAnimate = cast obj;
				spr.active = false;
				if(hide) spr.visible = false;
				return true;
			}
			return false;
		});
		
		Lua_helper.add_callback(lua, "addAnimationBySymbol", function(tag:String, name:String, symbol:String, ?framerate:Float = 24, ?loop:Bool = false, ?matX:Float = 0, ?matY:Float = 0)
		{
			var obj:Dynamic = MusicBeatState.getVariables().get(tag);
			if(obj == null || !Std.isOfType(obj, FlxAnimate)) return false;
			var spr:FlxAnimate = cast obj;

			spr.anim.addBySymbol(name, symbol, framerate, loop, matX, matY);
			if(spr.anim.curSymbol == null)
			{
				if(Std.isOfType(spr, ModchartAnimateSprite))
				{
					var obj2:ModchartAnimateSprite = cast spr;
					obj2.playAnim(name, true);
				}
				else spr.anim.play(name, true);
			}
			return true;
		});

		Lua_helper.add_callback(lua, "addAnimationBySymbolIndices", function(tag:String, name:String, symbol:String, ?indices:Any = null, ?framerate:Float = 24, ?loop:Bool = false, ?matX:Float = 0, ?matY:Float = 0)
		{
			var obj:Dynamic = MusicBeatState.getVariables().get(tag);
			if(obj == null || !Std.isOfType(obj, FlxAnimate)) return false;
			var spr:FlxAnimate = cast obj;

			if(indices == null)
				indices = [0];
			else if(Std.isOfType(indices, String))
			{
				var strIndices:Array<String> = cast (indices, String).trim().split(',');
				var myIndices:Array<Int> = [];
				for (i in 0...strIndices.length) {
					myIndices.push(Std.parseInt(strIndices[i]));
				}
				indices = myIndices;
			}

			spr.anim.addBySymbolIndices(name, symbol, indices, framerate, loop, matX, matY);
			if(spr.anim.curSymbol == null)
			{
				if(Std.isOfType(spr, ModchartAnimateSprite))
				{
					var obj2:ModchartAnimateSprite = cast spr;
					obj2.playAnim(name, true);
				}
				else spr.anim.play(name, true);
			}
			return true;
		});
	}
}
#end

package psychlua;

class TextFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		Lua_helper.add_callback(lua, "makeLuaText", function(tag:String, ?text:String = '', ?width:Int = 0, ?x:Float = 0, ?y:Float = 0) {
			tag = tag.replace('.', '');

			LuaUtils.destroyObject(tag);
			var leText:FlxText = new FlxText(x, y, width, text, 16);
			leText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			if(PlayState.instance != null) leText.cameras = [PlayState.instance.camHUD];
			leText.scrollFactor.set();
			leText.borderSize = 2;
			MusicBeatState.getVariables().set(tag, leText);
		});

		Lua_helper.add_callback(lua, "setTextString", function(tag:String, text:String) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1])) : LuaUtils.getObjectDirectly(split[0]);
			if(obj != null)
			{
				obj.text = text;
				return true;
			}
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_textfunctions.settextstring_object_value_doesn_t_exist', "setTextString: Object {1} doesn't exist!", [tag]), false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "setTextSize", function(tag:String, size:Int) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1])) : LuaUtils.getObjectDirectly(split[0]);
			if(obj != null)
			{
				obj.size = size;
				return true;
			}
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_textfunctions.settextsize_object_value_doesn_t_exist', "setTextSize: Object {1} doesn't exist!", [tag]), false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "setTextWidth", function(tag:String, width:Float) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1])) : LuaUtils.getObjectDirectly(split[0]);
			if(obj != null)
			{
				obj.fieldWidth = width;
				return true;
			}
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_textfunctions.settextwidth_object_value_doesn_t_exist', "setTextWidth: Object {1} doesn't exist!", [tag]), false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "setTextHeight", function(tag:String, height:Float) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1])) : LuaUtils.getObjectDirectly(split[0]);
			if(obj != null)
			{
				obj.fieldHeight = height;
				return true;
			}
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_textfunctions.settextheight_object_value_doesn_t_exist', "setTextHeight: Object {1} doesn't exist!", [tag]), false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "setTextAutoSize", function(tag:String, value:Bool) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1])) : LuaUtils.getObjectDirectly(split[0]);
			if(obj != null)
			{
				obj.autoSize = value;
				return true;
			}
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_textfunctions.settextautosize_object_value_doesn_t_exist', "setTextAutoSize: Object {1} doesn't exist!", [tag]), false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "setTextBorder", function(tag:String, size:Float, color:String, ?style:String = 'outline') {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1])) : LuaUtils.getObjectDirectly(split[0]);
			if(obj != null)
			{
				CoolUtil.setTextBorderFromString(obj, (size > 0 ? style : 'none'));
				if(size > 0)
					obj.borderSize = size;
				
				obj.borderColor = CoolUtil.colorFromString(color);
				return true;
			}
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_textfunctions.settextborder_object_value_doesn_t_exist', "setTextBorder: Object {1} doesn't exist!", [tag]), false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "setTextColor", function(tag:String, color:String) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1])) : LuaUtils.getObjectDirectly(split[0]);
			if(obj != null)
			{
				obj.color = CoolUtil.colorFromString(color);
				return true;
			}
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_textfunctions.settextcolor_object_value_doesn_t_exist', "setTextColor: Object {1} doesn't exist!", [tag]), false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "setTextFont", function(tag:String, newFont:String) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1])) : LuaUtils.getObjectDirectly(split[0]);
			if(obj != null)
			{
				obj.font = Paths.font(newFont);
				return true;
			}
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_textfunctions.settextfont_object_value_doesn_t_exist', "setTextFont: Object {1} doesn't exist!", [tag]), false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "setTextItalic", function(tag:String, italic:Bool) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1])) : LuaUtils.getObjectDirectly(split[0]);
			if(obj != null)
			{
				obj.italic = italic;
				return true;
			}
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_textfunctions.settextitalic_object_value_doesn_t_exist', "setTextItalic: Object {1} doesn't exist!", [tag]), false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "setTextAlignment", function(tag:String, alignment:String = 'left') {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1])) : LuaUtils.getObjectDirectly(split[0]);
			if(obj != null)
			{
				obj.alignment = LEFT;
				switch(alignment.trim().toLowerCase())
				{
					case 'right':
						obj.alignment = RIGHT;
					case 'center':
						obj.alignment = CENTER;
					case 'justify':
						obj.alignment = JUSTIFY;
				}
				return true;
			}
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_textfunctions.settextalignment_object_value_doesn_t_exist', "setTextAlignment: Object {1} doesn't exist!", [tag]), false, false, FlxColor.RED);
			return false;
		});

		Lua_helper.add_callback(lua, "getTextString", function(tag:String) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1])) : LuaUtils.getObjectDirectly(split[0]);
			if(obj != null && obj.text != null)
			{
				return obj.text;
			}
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_textfunctions.gettextstring_object_value_doesn_t_exist', "getTextString: Object {1} doesn't exist!", [tag]), false, false, FlxColor.RED);
			return null;
		});
		Lua_helper.add_callback(lua, "getTextSize", function(tag:String) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1])) : LuaUtils.getObjectDirectly(split[0]);
			if(obj != null)
			{
				return obj.size;
			}
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_textfunctions.gettextsize_object_value_doesn_t_exist', "getTextSize: Object {1} doesn't exist!", [tag]), false, false, FlxColor.RED);
			return -1;
		});
		Lua_helper.add_callback(lua, "getTextFont", function(tag:String) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1])) : LuaUtils.getObjectDirectly(split[0]);
			if(obj != null)
			{
				return obj.font;
			}
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_textfunctions.gettextfont_object_value_doesn_t_exist', "getTextFont: Object {1} doesn't exist!", [tag]), false, false, FlxColor.RED);
			return null;
		});
		Lua_helper.add_callback(lua, "getTextWidth", function(tag:String) {
			var split:Array<String> = tag.split('.');
			var obj:FlxText = split.length > 1 ? (LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1])) : LuaUtils.getObjectDirectly(split[0]);
			if(obj != null)
			{
				return obj.fieldWidth;
			}
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_textfunctions.gettextwidth_object_value_doesn_t_exist', "getTextWidth: Object {1} doesn't exist!", [tag]), false, false, FlxColor.RED);
			return 0;
		});

		Lua_helper.add_callback(lua, "addLuaText", function(tag:String) {
			var text:FlxText = MusicBeatState.getVariables().get(tag);
			if(text != null) LuaUtils.getTargetInstance().add(text);
		});
		Lua_helper.add_callback(lua, "removeLuaText", function(tag:String, destroy:Bool = true) {
			var variables = MusicBeatState.getVariables();
			var text:FlxText = variables.get(tag);
			if(text == null) return;

			var instance:Dynamic = CustomSubstate.instance != null ? CustomSubstate.instance : LuaUtils.getTargetInstance();
			instance.remove(text, true);
			if(destroy)
			{
				text.destroy();
				variables.remove(tag);
			}
		});
	}
}

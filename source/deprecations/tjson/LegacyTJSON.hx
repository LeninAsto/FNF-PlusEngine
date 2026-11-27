package deprecations.tjson;

import deprecations.HaxeLibDeprecations;
import jsonmod.EncodeStyle;

@:keep
class LegacyTJSON
{
	public static var OBJECT_REFERENCE_PREFIX:String = '@~obRef#';

	public static function parse(json:String, ?fileName:String = 'JSON Data', ?stringProcessor:String->Dynamic):Dynamic
	{
		HaxeLibDeprecations.warn('tjson.TJSON.parse', 'jsonmod.Json.parse');
		if (json.indexOf('_hxcls') >= 0 || json.indexOf(OBJECT_REFERENCE_PREFIX) >= 0)
		{
			LegacyCodec.OBJECT_REFERENCE_PREFIX = OBJECT_REFERENCE_PREFIX;
			return LegacyCodec.parse(json, fileName, stringProcessor);
		}
		try return jsonmod.Json.parse(json)
		catch (_:Dynamic) return LegacyCodec.parse(json, fileName, stringProcessor);
	}

	public static function encode(value:Dynamic, ?style:Dynamic, useCache:Bool = true):String
	{
		HaxeLibDeprecations.warn('tjson.TJSON.encode', 'jsonmod.Json.encode');
		if (style != null && Std.isOfType(style, EncodeStyle))
			return jsonmod.Json.encode(value, cast style);
		if (style == null && useCache && !requiresLegacy(value, []))
			return jsonmod.Json.encode(value);
		LegacyCodec.OBJECT_REFERENCE_PREFIX = OBJECT_REFERENCE_PREFIX;
		return LegacyCodec.encode(value, style, useCache);
	}

	static function requiresLegacy(value:Dynamic, seen:Array<Dynamic>):Bool
	{
		if (value == null || Std.isOfType(value, String) || !Reflect.isObject(value)) return false;
		if (seen.indexOf(value) >= 0) return true;
		seen.push(value);
		if (Std.isOfType(value, Array))
		{
			for (item in (cast value:Array<Dynamic>))
				if (requiresLegacy(item, seen)) return true;
			return false;
		}
		if (Type.getClass(value) != null) return true;
		for (field in Reflect.fields(value))
			if (requiresLegacy(Reflect.field(value, field), seen)) return true;
		return false;
	}
}

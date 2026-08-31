package macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

class PlusFlxMacro
{
	public static macro function buildFlxBasic():Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();
		if (!hasField(fields, "zIndex"))
		{
			fields.push({
				name: "zIndex",
				access: [APublic],
				kind: FVar(macro :Int, macro $v{0}),
				pos: Context.currentPos()
			});
		}
		return fields;
	}

	public static macro function buildFlxSprite():Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();
		if (!hasField(fields, "getCamerasLegacy"))
		{
			fields.push({
				name: "getCamerasLegacy",
				access: [APublic],
				kind: FFun({
					args: [],
					ret: macro :Array<flixel.FlxCamera>,
					expr: macro return cameras
				}),
				pos: Context.currentPos()
			});
		}
		return fields;
	}

	public static macro function buildFlxPath():Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();
		if (!hasField(fields, "drawDebugOnCamera"))
		{
			fields.push({
				name: "drawDebugOnCamera",
				access: [APublic],
				kind: FFun({
					args: [{name: "camera", type: macro :flixel.FlxCamera}],
					ret: macro :Void,
					expr: macro drawDebug(camera)
				}),
				pos: Context.currentPos()
			});
		}
		return fields;
	}

	static function hasField(fields:Array<Field>, name:String):Bool
	{
		for (field in fields)
			if (field.name == name)
				return true;
		return false;
	}
}
#end

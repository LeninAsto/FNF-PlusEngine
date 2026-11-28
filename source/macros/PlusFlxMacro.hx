package macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

class PlusFlxMacro
{
	public static macro function buildFlxText():Array<Field>
	{
		var fields = Context.getBuildFields();
		for (field in fields)
		{
			if (field.name != 'set_antialiasing') continue;
			switch (field.kind)
			{
				case FFun(fn):
					switch (fn.expr.expr)
					{
						case EBlock(exprs):
							exprs.unshift(macro value = true);
						default: Context.error('Unexpected FlxText antialiasing setter', field.pos);
					}
				default: Context.error('Unexpected FlxText antialiasing setter', field.pos);
			}
			return fields;
		}
		Context.error('FlxText antialiasing setter not found', Context.currentPos());
		return fields;
	}

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

	public static macro function buildFlxPath():Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();
		if (!hasField(fields, "drawDebugOnCamera"))
		{
			var body:Expr = if (Context.defined("FLX_DEBUG")) macro drawDebug(camera) else macro {};
			fields.push({
				name: "drawDebugOnCamera",
				access: [APublic],
				kind: FFun({
					args: [{name: "camera", type: macro :flixel.FlxCamera}],
					ret: macro :Void,
					expr: body
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

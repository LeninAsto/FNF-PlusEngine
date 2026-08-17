package shaders;

class ShaderCompatibility
{
	public static function adaptRuntimeShaderCode(source:String, shaderName:String = null, stage:String = "fragment"):String
	{
		if (source == null)
			return null;

		var code:String = source.replace("\r\n", "\n").replace("\r", "\n");
		code = stripUniformInitializers(code);
		code = normalizeStrictConstructors(code);
		return code;
	}

	static function stripUniformInitializers(source:String):String
	{
		var uniformInit:EReg = ~/^(\s*uniform\s+(?:(?:lowp|mediump|highp)\s+)?[A-Za-z_][A-Za-z0-9_]*\s+[A-Za-z_][A-Za-z0-9_]*(?:\s*\[[^\]]+\])?)\s*=\s*[^;]+;\s*$/;
		var lines:Array<String> = source.split("\n");
		for (i in 0...lines.length)
		{
			var line:String = lines[i];
			if (uniformInit.match(line))
				lines[i] = uniformInit.matched(1) + ";";
		}
		return lines.join("\n");
	}

	static function normalizeStrictConstructors(source:String):String
	{
		var code:String = source;
		for (typeName in ["mat2", "mat3", "mat4", "vec2", "vec3", "vec4"])
		{
			code = code.replace(typeName + "(0)", typeName + "(0.0)");
			code = code.replace(typeName + "(1)", typeName + "(1.0)");
		}
		return code;
	}
}


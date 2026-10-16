package shaders;

private typedef ShaderSourceToken =
{
	var text:String;
	var kind:Int;
}

class ShaderCompatibility
{
	public static function adaptRuntimeShaderCode(source:String, shaderName:String = null, stage:String = "fragment"):String
	{
		if (source == null)
			return null;

		var code:String = source.replace("\r\n", "\n").replace("\r", "\n");
		if (code.length > 0 && code.charCodeAt(0) == 0xFEFF)
			code = code.substr(1);
		code = normalizeVersionDirective(code);
		var dialect:String = getShaderDialect(code, shaderName);

		if (dialect != null)
			code = stripDialectPragmas(code);
		code = stripUniformInitializers(code);
		code = localizeOpenFLGlobalInitializers(code);

		if (stage == "fragment" && dialect != null)
		{
			switch (dialect)
			{
				case "notitg":
					code = adaptNotITGFragment(code);
				case "shadertoy":
					code = adaptShadertoyFragment(code);
				default:
			}
		}

		code = normalizeNumericArithmetic(code);
		return normalizeStrictConstructors(code);
	}

	/**
	 * Keeps a single version directive at the beginning of runtime shaders and
	 * maps the common desktop/ES versions to the active target. OpenFL inserts
	 * its precision prefix immediately after this directive.
	 */
	static function normalizeVersionDirective(source:String):String
	{
		var lines:Array<String> = source.split("\n");
		var version:EReg = ~/^\s*#version\s+([0-9]+)/i;
		var requested:Int = 0;
		var body:Array<String> = [];

		for (line in lines)
		{
			if (version.match(line))
			{
				if (requested == 0)
					requested = Std.parseInt(version.matched(1));
				continue;
			}
			body.push(line);
		}

		if (requested == 0)
			return source;

		#if (android || ios)
		var targetVersion:String = requested >= 300 ? "#version 300 es" : "#version 100";
		#else
		var targetVersion:String = requested >= 300 ? "#version 330" : "#version 120";
		#end

		return targetVersion + "\n" + body.join("\n");
	}

	static function getShaderDialect(source:String, shaderName:String):String
	{
		var lower:String = source.toLowerCase();
		if (hasDialectFlag(lower, "notitg"))
			return "notitg";
		if (hasDialectFlag(lower, "shadertoy"))
			return "shadertoy";

		if (shaderName != null)
		{
			var name:String = shaderName.toLowerCase();
			if (StringTools.startsWith(name, "notitg:") || StringTools.startsWith(name, "notitg/"))
				return "notitg";
			if (StringTools.startsWith(name, "shadertoy:") || StringTools.startsWith(name, "shadertoy/"))
				return "shadertoy";
		}

		return null;
	}

	static function hasDialectFlag(source:String, dialect:String):Bool
	{
		return source.indexOf("#pragma " + dialect) != -1
			|| source.indexOf("#pragma shader_dialect " + dialect) != -1
			|| source.indexOf("#pragma shader-dialect " + dialect) != -1
			|| source.indexOf("@shader_dialect " + dialect) != -1
			|| source.indexOf("@shader-dialect " + dialect) != -1;
	}

	static function stripDialectPragmas(source:String):String
	{
		var lines:Array<String> = source.split("\n");
		for (i in 0...lines.length)
		{
			var line:String = lines[i];
			var lower:String = StringTools.trim(line).toLowerCase();
			if (StringTools.startsWith(lower, "#pragma notitg")
				|| StringTools.startsWith(lower, "#pragma shadertoy")
				|| StringTools.startsWith(lower, "#pragma shader_dialect")
				|| StringTools.startsWith(lower, "#pragma shader-dialect")
				|| lower.indexOf("@shader_dialect ") != -1
				|| lower.indexOf("@shader-dialect ") != -1)
			{
				lines[i] = "";
			}
		}
		return lines.join("\n");
	}

	static function stripVersionPragmas(source:String):String
	{
		var version:EReg = ~/^\s*#version\s+[0-9]+\s*.*$/gm;
		return version.replace(source, "");
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

	static function localizeOpenFLGlobalInitializers(source:String):String
	{
		var lines:Array<String> = source.split("\n");
		var declarations:Array<String> = [];
		var globalInit:EReg = ~/^\s*((?:(?:lowp|mediump|highp)\s+)?(?:float|int|bool|vec[234]|mat[234])\s+[A-Za-z_][A-Za-z0-9_]*\s*=\s*[^;]*openfl_[^;]*;)\s*$/;
		var depth:Int = 0;

		for (i in 0...lines.length)
		{
			var line:String = lines[i];
			if (depth == 0 && globalInit.match(line))
			{
				declarations.push("\t" + StringTools.trim(globalInit.matched(1)));
				lines[i] = "";
			}

			depth += countChar(line, "{");
			depth -= countChar(line, "}");
			if (depth < 0)
				depth = 0;
		}

		if (declarations.length == 0)
			return lines.join("\n");

		var output:Array<String> = [];
		var waitingMainBrace:Bool = false;
		var inserted:Bool = false;
		var wrappingMain:Bool = false;
		var mainBaseDepth:Int = 0;
		var outputDepth:Int = 0;
		var mainDecl:EReg = ~/^\s*void\s+(?:main|mainImage)\s*\(/;

		for (line in lines)
		{
			var opens:Int = countChar(line, "{");
			var closes:Int = countChar(line, "}");

			// Keep the original function body in a nested scope. GLSL permits a
			// local to shadow a global, so moving both into the same scope would
			// otherwise break valid legacy shaders (for example, `uv`).
			if (wrappingMain && outputDepth + opens - closes <= mainBaseDepth)
			{
				output.push("\t}");
				wrappingMain = false;
			}

			output.push(line);

			if (!inserted && mainDecl.match(line))
			{
				if (line.indexOf("{") != -1)
				{
					for (declaration in declarations)
						output.push(declaration);
					output.push("\t{");
					mainBaseDepth = outputDepth;
					wrappingMain = true;
					inserted = true;
				}
				else
					waitingMainBrace = true;
				continue;
			}

			if (!inserted && waitingMainBrace && line.indexOf("{") != -1)
			{
				for (declaration in declarations)
					output.push(declaration);
				output.push("\t{");
				mainBaseDepth = outputDepth;
				wrappingMain = true;
				inserted = true;
				waitingMainBrace = false;
			}

			outputDepth += opens - closes;
			if (outputDepth < 0)
				outputDepth = 0;
		}

		if (!inserted)
			output = declarations.concat(output);

		return output.join("\n");
	}

	static function countChar(source:String, char:String):Int
	{
		var count:Int = 0;
		for (i in 0...source.length)
			if (source.charAt(i) == char)
				count++;
		return count;
	}

	static function adaptNotITGFragment(source:String):String
	{
		var code:String = source;
		var needsHeader:Bool = code.indexOf("#pragma header") == -1;
		var usedLegacyColor:Bool = code.indexOf("color") != -1;

		code = stripVersionPragmas(code);
		code = removeBuiltinDeclarations(code);
		code = replaceWord(code, "sampler0", "bitmap");
		code = replaceWord(code, "imageCoord", "openfl_TextureCoordv");
		code = replaceWord(code, "textureCoord", "openfl_TextureCoordv");
		code = replaceWord(code, "imageSize", "openfl_TextureSize");
		code = replaceWord(code, "textureSize", "openfl_TextureSize");
		code = replaceWord(code, "resolution", "openfl_TextureSize");
		code = replaceTexture2DBiasCalls(code);

		if (usedLegacyColor)
			code = "#define color vec4(1.0)\n" + code;
		if (needsHeader)
			code = "#pragma header\n\n" + code;

		return code;
	}

	static function adaptShadertoyFragment(source:String):String
	{
		var code:String = stripVersionPragmas(source);
		var needsHeader:Bool = code.indexOf("#pragma header") == -1;
		var usesITime:Bool = code.indexOf("iTime") != -1;
		var hasITimeUniform:Bool = code.indexOf("uniform float iTime") != -1;

		code = removeBuiltinDeclarations(code, [
			"iResolution" => true,
			"iChannel0" => true
		]);
		code = replaceWord(code, "iResolution", "vec3(openfl_TextureSize, 1.0)");
		code = replaceWord(code, "iChannel0", "bitmap");
		code = replaceWord(code, "texture", "texture2D");

		if (usesITime && !hasITimeUniform)
			code = "uniform float iTime;\n" + code;

		if (code.indexOf("void mainImage") != -1 && code.indexOf("void main()") == -1)
		{
			code += "\n\nvoid main()\n{\n\tvec4 fragColor = vec4(0.0);\n\tmainImage(fragColor, openfl_TextureCoordv * openfl_TextureSize);\n\tgl_FragColor = fragColor;\n}\n";
		}

		if (needsHeader)
			code = "#pragma header\n\n" + code;

		return code;
	}

	static function removeBuiltinDeclarations(source:String, ?builtins:Map<String, Bool>):String
	{
		var lines:Array<String> = source.split("\n");
		if (builtins == null)
		{
			builtins = [
				"color" => true,
				"textureCoord" => true,
				"imageCoord" => true,
				"textureSize" => true,
				"imageSize" => true,
				"resolution" => true,
				"sampler0" => true
			];
		}

		for (i in 0...lines.length)
		{
			var trimmed:String = StringTools.trim(lines[i]);
			if (isBuiltinDeclaration(trimmed, builtins))
				lines[i] = "";
		}
		return lines.join("\n");
	}

	static function isBuiltinDeclaration(line:String, builtins:Map<String, Bool>):Bool
	{
		if (!(StringTools.startsWith(line, "uniform ") || StringTools.startsWith(line, "varying ")))
			return false;
		if (!StringTools.endsWith(line, ";"))
			return false;

		var declaration:String = line.substr(0, line.length - 1);
		var parts:Array<String> = declaration.split(" ");
		if (parts.length < 3)
			return false;

		var name:String = parts[parts.length - 1];
		var bracket:Int = name.indexOf("[");
		if (bracket != -1)
			name = name.substr(0, bracket);
		return builtins.exists(name);
	}

	static function replaceTexture2DBiasCalls(source:String):String
	{
		var code:String = source;
		var search:String = "texture2D(";
		var index:Int = code.indexOf(search);
		while (index != -1)
		{
			var startArgs:Int = index + search.length;
			var end:Int = findMatchingParen(code, startArgs - 1);
			if (end == -1)
				break;

			var args:String = code.substr(startArgs, end - startArgs);
			var split:Array<String> = splitTopLevelArgs(args);
			if (split.length >= 2)
			{
				var sampler:String = StringTools.trim(split[0]);
				var coord:String = StringTools.trim(split[1]);
				var functionName:String = sampler == "bitmap" ? "flixel_texture2D" : "texture2D";
				var replacement:String = functionName + "(" + sampler + ", " + coord + ")";
				code = code.substr(0, index) + replacement + code.substr(end + 1);
				index = code.indexOf(search, index + replacement.length);
			}
			else
				index = code.indexOf(search, end + 1);
		}
		return code;
	}

	static function splitTopLevelArgs(args:String):Array<String>
	{
		var result:Array<String> = [];
		var depth:Int = 0;
		var start:Int = 0;
		for (i in 0...args.length)
		{
			var char:String = args.charAt(i);
			switch (char)
			{
				case "(":
					depth++;
				case ")":
					if (depth > 0)
						depth--;
				case ",":
					if (depth == 0)
					{
						result.push(args.substr(start, i - start));
						start = i + 1;
					}
				default:
			}
		}
		result.push(args.substr(start));
		return result;
	}

	static function findMatchingParen(source:String, openIndex:Int):Int
	{
		var depth:Int = 0;
		for (i in openIndex...source.length)
		{
			var char:String = source.charAt(i);
			if (char == "(")
				depth++;
			else if (char == ")")
			{
				depth--;
				if (depth == 0)
					return i;
			}
		}
		return -1;
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

	/**
	 * GLSL desktop drivers commonly accept arithmetic between a float/vector
	 * and an integer literal. GLSL ES drivers are stricter and reject examples
	 * such as `red / 255` or `2 * color`. Convert only literals whose other
	 * operand is known to be floating-point, leaving integer loops, array
	 * indices and ivec/uvec expressions untouched.
	 */
	static function normalizeNumericArithmetic(source:String):String
	{
		var tokens:Array<ShaderSourceToken> = tokenizeShaderSource(source);
		var floatingNames:Map<String, Bool> = collectFloatingNames(tokens);

		for (i in 0...tokens.length)
		{
			var token:ShaderSourceToken = tokens[i];
			if (token.kind != NUMBER_TOKEN || !isPlainIntegerLiteral(token.text))
				continue;

			var previous:Int = previousCodeToken(tokens, i - 1);
			var next:Int = nextCodeToken(tokens, i + 1);
			var needsFloat:Bool = false;

			if (previous >= 0 && isArithmeticOperator(tokens[previous].text))
			{
				var leftOperand:Int = previousCodeToken(tokens, previous - 1);
				needsFloat = isFloatingOperand(tokens, leftOperand, -1, floatingNames);
			}
			if (!needsFloat && next >= 0 && isArithmeticOperator(tokens[next].text))
			{
				var rightOperand:Int = nextCodeToken(tokens, next + 1);
				needsFloat = isFloatingOperand(tokens, rightOperand, 1, floatingNames);
			}

			if (needsFloat)
				token.text += ".0";
		}

		var output:StringBuf = new StringBuf();
		for (token in tokens)
			output.add(token.text);
		return output.toString();
	}

	static inline var TRIVIA_TOKEN:Int = 0;
	static inline var IDENTIFIER_TOKEN:Int = 1;
	static inline var NUMBER_TOKEN:Int = 2;
	static inline var SYMBOL_TOKEN:Int = 3;

	static function tokenizeShaderSource(source:String):Array<ShaderSourceToken>
	{
		var tokens:Array<ShaderSourceToken> = [];
		var i:Int = 0;
		while (i < source.length)
		{
			var start:Int = i;
			var code:Int = source.charCodeAt(i);

			if (isWhitespaceCode(code))
			{
				i++;
				while (i < source.length && isWhitespaceCode(source.charCodeAt(i)))
					i++;
				tokens.push({text: source.substr(start, i - start), kind: TRIVIA_TOKEN});
				continue;
			}

			if (source.charAt(i) == "/" && i + 1 < source.length)
			{
				var nextChar:String = source.charAt(i + 1);
				if (nextChar == "/")
				{
					i += 2;
					while (i < source.length && source.charAt(i) != "\n")
						i++;
					tokens.push({text: source.substr(start, i - start), kind: TRIVIA_TOKEN});
					continue;
				}
				if (nextChar == "*")
				{
					i += 2;
					while (i + 1 < source.length && !(source.charAt(i) == "*" && source.charAt(i + 1) == "/"))
						i++;
					if (i + 1 < source.length)
						i += 2;
					tokens.push({text: source.substr(start, i - start), kind: TRIVIA_TOKEN});
					continue;
				}
			}

			if (isIdentifierStart(code))
			{
				i++;
				while (i < source.length && isIdentifierPart(source.charCodeAt(i)))
					i++;
				tokens.push({text: source.substr(start, i - start), kind: IDENTIFIER_TOKEN});
				continue;
			}

			if (code >= "0".code && code <= "9".code)
			{
				i++;
				while (i < source.length)
				{
					var numericCode:Int = source.charCodeAt(i);
					var numericChar:String = source.charAt(i);
					if ((numericCode >= "0".code && numericCode <= "9".code) || numericChar == "." || numericChar == "e" || numericChar == "E"
						|| numericChar == "f" || numericChar == "F" || numericChar == "u" || numericChar == "U")
					{
						i++;
						continue;
					}
					if ((numericChar == "+" || numericChar == "-") && i > start && (source.charAt(i - 1) == "e" || source.charAt(i - 1) == "E"))
					{
						i++;
						continue;
					}
					break;
				}
				tokens.push({text: source.substr(start, i - start), kind: NUMBER_TOKEN});
				continue;
			}

			i++;
			tokens.push({text: source.substr(start, 1), kind: SYMBOL_TOKEN});
		}
		return tokens;
	}

	static function collectFloatingNames(tokens:Array<ShaderSourceToken>):Map<String, Bool>
	{
		var names:Map<String, Bool> = [
			"openfl_Alphav" => true,
			"openfl_ColorMultiplierv" => true,
			"openfl_ColorOffsetv" => true,
			"openfl_TextureCoordv" => true,
			"openfl_TextureSize" => true,
			"gl_FragCoord" => true,
			"gl_PointCoord" => true
		];

		for (i in 0...tokens.length)
		{
			if (tokens[i].kind != IDENTIFIER_TOKEN || !isFloatingType(tokens[i].text))
				continue;
			var nameIndex:Int = nextCodeToken(tokens, i + 1);
			if (nameIndex >= 0 && tokens[nameIndex].kind == IDENTIFIER_TOKEN)
				names.set(tokens[nameIndex].text, true);
		}
		return names;
	}

	static function isFloatingOperand(tokens:Array<ShaderSourceToken>, index:Int, direction:Int, names:Map<String, Bool>):Bool
	{
		if (index < 0 || index >= tokens.length)
			return false;

		var token:ShaderSourceToken = tokens[index];
		if (token.kind == IDENTIFIER_TOKEN)
		{
			var baseIndex:Int = index;
			if (direction < 0)
			{
				var dot:Int = previousCodeToken(tokens, index - 1);
				if (dot >= 0 && tokens[dot].text == ".")
				{
					var possibleBase:Int = previousCodeToken(tokens, dot - 1);
					if (possibleBase >= 0)
						baseIndex = possibleBase;
				}
			}
			if (tokens[baseIndex].kind == IDENTIFIER_TOKEN && names.exists(tokens[baseIndex].text))
				return true;

			var paren:Int = direction > 0 ? nextCodeToken(tokens, index + 1) : -1;
			return paren >= 0 && tokens[paren].text == "(" && isFloatingFunction(token.text);
		}

		if (token.text == "(" && direction > 0)
			return isFloatingOperand(tokens, nextCodeToken(tokens, index + 1), direction, names);

		if (token.text == ")" && direction < 0)
		{
			var depth:Int = 1;
			var cursor:Int = previousCodeToken(tokens, index - 1);
			while (cursor >= 0)
			{
				if (tokens[cursor].text == ")")
					depth++;
				else if (tokens[cursor].text == "(")
				{
					depth--;
					if (depth == 0)
					{
						var functionIndex:Int = previousCodeToken(tokens, cursor - 1);
						return functionIndex >= 0 && tokens[functionIndex].kind == IDENTIFIER_TOKEN && isFloatingFunction(tokens[functionIndex].text);
					}
				}
				cursor = previousCodeToken(tokens, cursor - 1);
			}
		}
		return false;
	}

	static inline function isArithmeticOperator(value:String):Bool
		return value == "+" || value == "-" || value == "*" || value == "/";

	static function isFloatingType(value:String):Bool
		return value == "float" || value == "double" || value == "vec2" || value == "vec3" || value == "vec4" || value == "mat2"
			|| value == "mat3" || value == "mat4";

	static function isFloatingFunction(value:String):Bool
	{
		if (isFloatingType(value))
			return true;
		return switch (value)
		{
			case "abs", "acos", "asin", "atan", "ceil", "clamp", "cos", "cross", "degrees", "distance", "dot", "exp", "exp2", "floor",
				"fract", "length", "log", "log2", "max", "min", "mix", "mod", "normalize", "pow", "radians", "reflect", "refract", "sign",
				"sin", "smoothstep", "sqrt", "step", "tan", "texture", "texture2D": true;
			default: false;
		}
	}

	static function isPlainIntegerLiteral(value:String):Bool
	{
		if (value.length == 0)
			return false;
		for (i in 0...value.length)
		{
			var code:Int = value.charCodeAt(i);
			if (code < "0".code || code > "9".code)
				return false;
		}
		return true;
	}

	static function previousCodeToken(tokens:Array<ShaderSourceToken>, index:Int):Int
	{
		var cursor:Int = index;
		while (cursor >= 0 && tokens[cursor].kind == TRIVIA_TOKEN)
			cursor--;
		return cursor;
	}

	static function nextCodeToken(tokens:Array<ShaderSourceToken>, index:Int):Int
	{
		var cursor:Int = index;
		while (cursor < tokens.length && tokens[cursor].kind == TRIVIA_TOKEN)
			cursor++;
		return cursor < tokens.length ? cursor : -1;
	}

	static inline function isWhitespaceCode(code:Int):Bool
		return code == 32 || code == 9 || code == 10 || code == 13;

	static inline function isIdentifierStart(code:Int):Bool
		return (code >= "a".code && code <= "z".code) || (code >= "A".code && code <= "Z".code) || code == "_".code;

	static inline function isIdentifierPart(code:Int):Bool
		return isIdentifierStart(code) || (code >= "0".code && code <= "9".code);

	static function hasAny(source:String, needles:Array<String>):Bool
	{
		for (needle in needles)
			if (source.indexOf(needle) != -1)
				return true;
		return false;
	}

	static function replaceWord(source:String, word:String, replacement:String):String
	{
		var reg:EReg = new EReg("\\b" + word + "\\b", "g");
		return reg.replace(source, replacement);
	}
}


package shaders;

import flixel.FlxG;

/**
 * Shader Compatibility System
 * Detects OpenGL version and adapts shader code for better compatibility
 * Based on P-Slice Engine's approach
 */
class ShaderCompatibility
{
	/**
	 * Stores the result of checking if the current device supports
	 * modern OpenGL (OpenGL 3.3+ / OpenGL ES 3.0+)
	 */
	private static var useNewerRendering:Null<Bool> = null;
	
	/**
	 * Detected OpenGL version string
	 */
	public static var glVersion:String = "Unknown";
	
	/**
	 * Detected GLSL version string
	 */
	public static var glslVersion:String = "Unknown";
	
	/**
	 * Initializes shader compatibility system and detects OpenGL version
	 */
	public static function init():Void
	{
		if (useNewerRendering != null) return; // Already initialized
		
		#if (!flash && sys)
		try {
			@:privateAccess
			var gl = FlxG.stage.context3D.gl;
			
			if (gl != null) {
				// Get OpenGL version
				glVersion = gl.getParameter(gl.VERSION);
				glslVersion = gl.getParameter(gl.SHADING_LANGUAGE_VERSION);
				
				// Determine if modern rendering is supported
				useNewerRendering = false;
				
				#if lime_opengles
				// OpenGL ES - check for 3.0+
				var version_part = StringTools.replace(glslVersion, "OpenGL ES GLSL ES ", "");
				var versionNum = Std.parseInt(StringTools.replace(version_part, ".", ""));
				useNewerRendering = (versionNum != null && versionNum >= 300);
				#else
				// Desktop OpenGL - check for 3.3+
				var versionNum = Std.parseInt(glslVersion.split(" ")[0].replace(".", ""));
				useNewerRendering = (versionNum != null && versionNum >= 330);
				#end
			} else {
				trace("Warning: Could not access OpenGL context");
				useNewerRendering = false;
			}
		} catch (e:Dynamic) {
			trace("Error detecting OpenGL version: " + e);
			useNewerRendering = false;
		}
		#else
		useNewerRendering = false;
		trace("Shader compatibility system: Platform does not support runtime shader detection");
		#end
	}
	
	/**
	 * Returns whether modern OpenGL rendering is supported
	 */
	public static function supportsModernGL():Bool
	{
		if (useNewerRendering == null) init();
		return useNewerRendering == true;
	}
	
	/**
	 * Adapts shader source code based on OpenGL version
	 * Converts modern GLSL 3.3+ syntax to legacy GLSL 1.2 if needed
	 * 
	 * @param fragmentSource Fragment shader source code
	 * @param vertexSource Vertex shader source code (optional)
	 * @return Adapted shader source as [fragment, vertex]
	 */
	public static function adaptShaderCode(fragmentSource:String, ?vertexSource:String):Array<String>
	{
		if (useNewerRendering == null) init();
		
		if (fragmentSource == null) fragmentSource = "";
		if (vertexSource == null) vertexSource = "";
		
		// If modern rendering is supported, return as-is
		if (useNewerRendering == true) {
			return [fragmentSource, vertexSource];
		}
		
		// Convert modern syntax to legacy
		var adaptedFragment = convertToLegacySyntax(fragmentSource);
		var adaptedVertex = convertToLegacySyntax(vertexSource);
		
		return [adaptedFragment, adaptedVertex];
	}
	
	/**
	 * Converts modern GLSL syntax to legacy GLSL syntax
	 */
	private static function convertToLegacySyntax(source:String):String
	{
		if (source == null || source == "") return source;
		
		var result = source;
		
		// Replace version directives using simple string replacement
		// Remove #version directives since we're targeting legacy
		if (result.indexOf("#version") != -1) {
			var lines = result.split("\n");
			var filtered = [];
			for (line in lines) {
				if (line.indexOf("#version") == -1) {
					filtered.push(line);
				}
			}
			result = filtered.join("\n");
		}
		
		// Convert modern keywords to legacy
		// Note: These are simple replacements, complex shaders may need manual adaptation
		result = StringTools.replace(result, " in ", " varying ");
		result = StringTools.replace(result, " out ", " varying ");
		result = StringTools.replace(result, "texture(", "texture2D(");
		
		// Handle specific GLSL 3.0+ features that don't exist in 1.2
		if (result.indexOf("output_FragColor") != -1) {
			result = StringTools.replace(result, "output_FragColor", "gl_FragColor");
		}
		
		return result;
	}
	
	/**
	 * Gets a shader compatibility report string
	 */
	public static function getCompatibilityReport():String
	{
		if (useNewerRendering == null) init();
		
		var report = "=== SHADER COMPATIBILITY ===\n";
		report += "OpenGL Version: " + glVersion + "\n";
		report += "GLSL Version: " + glslVersion + "\n";
		report += "Modern Rendering: " + (useNewerRendering ? "Supported" : "Not Supported") + "\n";
		report += "Shader Mode: " + (useNewerRendering ? "GLSL 3.3+ (Modern)" : "GLSL 1.2 (Legacy)") + "\n";
		
		if (!useNewerRendering) {
			report += "\nNote: Your GPU may have limited shader support.\n";
			report += "Complex shader effects may not work correctly.\n";
		}
		
		report += "============================\n";
		
		return report;
	}
}

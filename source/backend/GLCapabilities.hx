package backend;

#if (!flash && sys)
import lime.graphics.opengl.GL;
#end

/** Cached feature levels for renderers that can safely use modern OpenGL paths. */
class GLCapabilities
{
	public static var initialized(default, null):Bool = false;
	public static var available(default, null):Bool = false;
	public static var isES(default, null):Bool = false;
	public static var major(default, null):Int = 0;
	public static var minor(default, null):Int = 0;
	public static var maxTextureSize(default, null):Int = 0;
	public static var vao(default, null):Bool = false;
	public static var instancing(default, null):Bool = false;
	public static var uniformBuffers(default, null):Bool = false;
	public static var textureArrays(default, null):Bool = false;
	public static var timerQueries(default, null):Bool = false;
	public static var compute(default, null):Bool = false;
	public static var shaderStorage(default, null):Bool = false;

	public static function init():Void
	{
		if (initialized) return;
		initialized = true;

		#if (!flash && sys)
		try
		{
			final raw = Native.getOpenGLVersion();
			if (raw == 'Unable to detect') return;

			isES = raw.toUpperCase().indexOf('OPENGL ES') != -1;
			final version = ~/([0-9]+)\.([0-9]+)/;
			if (!version.match(raw)) return;
			major = Std.parseInt(version.matched(1));
			minor = Std.parseInt(version.matched(2));
			available = major >= 2;

			var extensions = new Map<String, Bool>();
			final supported = GL.getSupportedExtensions();
			if (supported != null)
				for (extension in supported)
					extensions.set(extension, true);

			final atLeast = (wantedMajor:Int, wantedMinor:Int) -> major > wantedMajor || (major == wantedMajor && minor >= wantedMinor);
			final has = (name:String) -> extensions.exists(name);

			vao = (isES && atLeast(3, 0)) || (!isES && atLeast(3, 0)) || has('GL_ARB_vertex_array_object') || has('GL_OES_vertex_array_object');
			instancing = (isES && atLeast(3, 0)) || (!isES && atLeast(3, 3)) || has('GL_ARB_instanced_arrays') || has('GL_EXT_instanced_arrays');
			uniformBuffers = (isES && atLeast(3, 0)) || (!isES && atLeast(3, 1)) || has('GL_ARB_uniform_buffer_object');
			textureArrays = (isES && atLeast(3, 0)) || (!isES && atLeast(3, 0)) || has('GL_EXT_texture_array');
			timerQueries = (!isES && atLeast(3, 3)) || has('GL_ARB_timer_query') || has('GL_EXT_disjoint_timer_query');
			compute = (isES && atLeast(3, 1)) || (!isES && atLeast(4, 3)) || has('GL_ARB_compute_shader');
			shaderStorage = (isES && atLeast(3, 1)) || (!isES && atLeast(4, 3)) || has('GL_ARB_shader_storage_buffer_object');

			final textureSize:Dynamic = GL.getParameter(GL.MAX_TEXTURE_SIZE);
			if (textureSize != null) maxTextureSize = Std.int(textureSize);
		}
		catch (_:Dynamic) {}
		#end
	}

	public static function tierLabel():String
	{
		init();
		if (!available) return 'Legacy';
		if (compute && shaderStorage) return 'Compute';
		if (vao && instancing && uniformBuffers) return 'Modern';
		return 'Legacy';
	}

	/** Stable feature query for scripts. Unknown names safely return false. */
	public static function supports(feature:String):Bool
	{
		init();
		if (feature == null) return false;
		return switch (feature.toLowerCase().split('-').join('').split('_').join('').split(' ').join(''))
		{
			case 'opengl', 'gl': available;
			case 'vao', 'vertexarrayobject': vao;
			case 'instancing', 'instancedarrays': instancing;
			case 'ubo', 'uniformbuffers': uniformBuffers;
			case 'texturearray', 'texturearrays': textureArrays;
			case 'timerquery', 'timerqueries': timerQueries;
			case 'compute', 'computeshader': compute;
			case 'ssbo', 'shaderstorage', 'shaderstoragebuffer': shaderStorage;
			default: false;
		}
	}
}

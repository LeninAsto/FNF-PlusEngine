package shaders;

import flixel.addons.display.FlxRuntimeShader;
import lime.graphics.opengl.GLProgram;

class ErrorHandledShader extends FlxShader implements IErrorHandler
{
	public static var brokenShaders:Map<String, Bool> = new Map<String, Bool>();
	public var shaderName:String = '';
	public var failed:Bool = false;
	public var lastError:Dynamic = null;
	public dynamic function onError(error:Dynamic):Void {}
	public function new(?shaderName:String)
	{
		this.shaderName = shaderName;
		super();
	}

	override function __createGLProgram(vertexSource:String, fragmentSource:String):GLProgram
	{
		try
		{
			final res = super.__createGLProgram(vertexSource, fragmentSource);
			return res;
		}
		catch (error)
		{
			failed = true;
			lastError = error;
			ErrorHandledShader.crashSave(this.shaderName, error, onError);
			return null;
		}
	}

	public static function isBroken(shaderName:String):Bool
		return shaderName != null && brokenShaders.exists(shaderName) && brokenShaders.get(shaderName);
	
	public static function crashSave(shaderName:String, error:Dynamic, onError:Dynamic) // prevent the app from dying immediately
	{
		if(shaderName == null) shaderName = 'unnamed';
		brokenShaders.set(shaderName, true);
		var alertTitle:String = 'Error on Shader: "$shaderName"';

		trace(error);

		try
		{
			var dateNow:String = Date.now().toString().replace(" ", "_").replace(":", "'");
			if (!FileSystem.exists('./logs/'))
				FileSystem.createDirectory('./logs/');

			var crashLogPath:String = './logs/shader_${shaderName}_${dateNow}.txt';
			File.saveContent(crashLogPath, Std.string(error));
			trace('$alertTitle - error log saved at: $crashLogPath');
		}
		catch (logError:Dynamic)
		{
			trace('$alertTitle - failed to save shader error log: $logError');
		}

		onError(error);
	}
}

class ErrorHandledRuntimeShader extends FlxRuntimeShader implements IErrorHandler
{
	public var shaderName:String = '';
	public var failed:Bool = false;
	public var lastError:Dynamic = null;
	public dynamic function onError(error:Dynamic):Void {}
	public function new(?shaderName:String, ?fragmentSource:String, ?vertexSource:String)
	{
		this.shaderName = shaderName;
		super(ShaderCompatibility.adaptRuntimeShaderCode(fragmentSource, shaderName, "fragment"), ShaderCompatibility.adaptRuntimeShaderCode(vertexSource, shaderName, "vertex"));
	}

	override function __createGLProgram(vertexSource:String, fragmentSource:String):GLProgram
	{
		try
		{
			final res = super.__createGLProgram(vertexSource, fragmentSource);
			return res;
		}
		catch (error)
		{
			failed = true;
			lastError = error;
			ErrorHandledShader.crashSave(this.shaderName, error, onError);
			return null;
		}
	}
}

interface IErrorHandler
{
	public var shaderName:String;
	public dynamic function onError(error:Dynamic):Void;
}

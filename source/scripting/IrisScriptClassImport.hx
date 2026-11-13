package scripting;

#if HSCRIPT_ALLOWED
import psychlua.backend.ScriptedClass.IScriptCustomConstructor;
import psychlua.backend.ScriptedClass.IScriptCustomBehaviour;
import hxscript.proxy.ReflectProxy;
import hxscript.types.IScriptedInstance;

/**
 * Constructor exposed to Iris for a class living in a mod's scripts/classes
 * directory. Iris calls hnew() for `new ImportedClass(...)`; hxscript keeps
 * ownership of the actual class and instance.
 */
class IrisScriptClassImport implements IScriptCustomConstructor implements IScriptCustomBehaviour
{
	public final path:String;
	public final mod:String;

	public function new(path:String, ?mod:String)
	{
		this.path = path;
		this.mod = mod;
	}

	public static function resolve(path:String, ?mod:String):IrisScriptClassImport
	{
		if (path == null || path.length == 0)
			return null;

		// Resolve now so failure remains an Iris import error, while the registry
		// caches the class for the later constructor call.
		return ScriptRegistry.resolveClass(path, mod) != null ? new IrisScriptClassImport(path, mod) : null;
	}

	public function hnew(args:Array<Dynamic>):Dynamic
	{
		return wrap(ScriptRegistry.instantiate(path, unwrapArgs(args), mod));
	}

	public function hget(name:String):Dynamic
	{
		var cls = ScriptRegistry.resolveClass(path, mod);
		if (cls == null)
			return null;

		var field:Dynamic = ReflectProxy.getProperty(cls, name);
		if (Reflect.isFunction(field))
		{
			return Reflect.makeVarArgs(function(args:Array<Dynamic>):Dynamic
			{
				return wrap(Reflect.callMethod(cls, field, unwrapArgs(args)));
			});
		}
		return wrap(field);
	}

	public function hset(name:String, val:Dynamic):Dynamic
	{
		var cls = ScriptRegistry.resolveClass(path, mod);
		if (cls != null)
			ReflectProxy.setProperty(cls, name, unwrap(val));
		return val;
	}

	public static function wrap(value:Dynamic):Dynamic
		return Std.isOfType(value, IScriptedInstance) ? new IrisScriptClassInstance(value) : value;

	public static function unwrap(value:Dynamic):Dynamic
		return Std.isOfType(value, IrisScriptClassInstance) ? cast(value, IrisScriptClassInstance).value : value;

	public static function unwrapArgs(args:Array<Dynamic>):Array<Dynamic>
	{
		if (args == null)
			return [];
		return [for (arg in args) unwrap(arg)];
	}
}

/** Makes an hxscript instance behave like a normal Iris object. */
class IrisScriptClassInstance implements IScriptCustomBehaviour
{
	public final value:Dynamic;

	public function new(value:Dynamic)
	{
		this.value = value;
	}

	public function hget(name:String):Dynamic
	{
		var field:Dynamic = ReflectProxy.getProperty(value, name);
		if (Reflect.isFunction(field))
		{
			return Reflect.makeVarArgs(function(args:Array<Dynamic>):Dynamic
			{
				return IrisScriptClassImport.wrap(Reflect.callMethod(value, field, IrisScriptClassImport.unwrapArgs(args)));
			});
		}
		return IrisScriptClassImport.wrap(field);
	}

	public function hset(name:String, val:Dynamic):Dynamic
	{
		ReflectProxy.setProperty(value, name, IrisScriptClassImport.unwrap(val));
		return val;
	}
}
#end

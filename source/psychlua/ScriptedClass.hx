package psychlua;

import backend.StructurePsychOld;
import crowplexus.hscript.Expr;
import crowplexus.hscript.Interp;
import psychlua.HScript.CustomInterp;

// ─────────────────────────────────────────────────────────
// Interfaces used by the scripted class system.
// Interp.hx in hscript-iris 1.1.3 references these by their
// fully-qualified names so it can stay lib-agnostic.
// ─────────────────────────────────────────────────────────

/**
 * Implement this on any Haxe class you want HScript to be able to
 * instantiate via `new ClassName(...)` when it is a scripted class.
 */
interface IScriptCustomConstructor
{
	public function hnew(args:Array<Dynamic>):Dynamic;
}

/**
 * Implement this on wrapper objects so the interpreter routes
 * get/set through `hget`/`hset` instead of Reflect.
 */
interface IScriptCustomBehaviour
{
	public function hget(name:String):Dynamic;
	public function hset(name:String, val:Dynamic):Dynamic;
}

interface IScriptSuperProxyProvider
{
	public function getScriptSuperProxy():Dynamic;
}

// ─────────────────────────────────────────────────────────
// Core handler: registered in customClasses map, acts as a
// factory ("class object") for each user-defined class.
// ─────────────────────────────────────────────────────────
class ScriptClassHandler implements IScriptCustomConstructor
{
	/** Parent interpreter that defined this class. **/
	public var ogInterp:Interp;

	/** Class name as written in script. **/
	public var name:String;

	/** Raw field/method expressions parsed from the class body. **/
	public var fields:Array<Expr>;

	/** Fully-qualified name of the class this one extends, or null. **/
	public var extend:String;

	/** Interfaces the class claims to implement (informational only). **/
	public var interfaces:Array<String>;

	public function new(ogInterp:Interp, name:String, fields:Array<Expr>, ?extend:String, ?interfaces:Array<String>)
	{
		this.ogInterp = ogInterp;
		this.name = name;
		this.fields = fields;
		this.extend = extend;
		this.interfaces = interfaces == null ? [] : interfaces;
	}

	/**
	 * Called by the interpreter when a script does `new ClassName(args)`.
	 * Creates a fresh ScriptClassInstance wrapping a ScriptTemplateBase
	 * (or an actual Haxe superclass if `extends` resolves to one).
	 */
	public function hnew(args:Array<Dynamic>):Dynamic
	{
		var childInterp:Interp = Std.isOfType(ogInterp, CustomInterp) ? new CustomInterp() : new Interp();

		// Copy all global variables from the parent interpreter so the
		// instance can access things like FlxG, PlayState, etc.
		for (key => value in ogInterp.variables)
		{
			childInterp.variables.set(key, value);
		}
		for (key => value in ogInterp.imports)
		{
			childInterp.imports.set(key, value);
		}
		for (key => value in ogInterp.customClasses)
		{
			childInterp.customClasses.set(key, value);
		}

		// Resolve the superclass. Try: variables → imports → Type.resolveClass.
		var superCl:Class<Dynamic> = null;
		if (extend != null)
		{
			var fromVar:Dynamic = ogInterp.variables.get(extend);
			if (fromVar == null)
				fromVar = ogInterp.imports.get(extend);
			if (fromVar == null && extend.contains('.'))
			{
				var shortName:String = extend.substr(extend.lastIndexOf('.') + 1);
				fromVar = ogInterp.variables.get(shortName);
				if (fromVar == null)
					fromVar = ogInterp.imports.get(shortName);
			}
			if (fromVar == null)
				fromVar = ogInterp.getOrImportClass(extend);
			if (Std.isOfType(fromVar, Class))
			{
				superCl = cast fromVar;
			}
			else
			{
				superCl = StructurePsychOld.resolveClass(extend);
				if (superCl == null)
					superCl = Type.resolveClass(extend + '_HSX');
			}
			if (superCl == null)
			{
				@:privateAccess ogInterp.error(ECustom('ScriptedClass: cannot resolve superclass "$extend"'));
			}
		}

		var instance:ScriptTemplateBase;
		if (superCl != null)
		{
			// Scripted adapters can provide the native instance they are extending.
			// This lets a scripted `extends BaseStage` run on the real BaseStage object
			// already registered in PlayState instead of spawning a second dummy stage.
			var superInstance:Dynamic = ogInterp.variables.get("__scriptedNativeSelf");
			if (superInstance == null || !Std.isOfType(superInstance, superCl))
			{
				var nativeAdapter:Dynamic = ScriptedNativeFactory.create(this, superCl, args);
				if (nativeAdapter != null)
					return nativeAdapter;
				superInstance = Type.createInstance(superCl, args);
			}

			instance = new ScriptTemplateBase();
			instance.__superInstance = superInstance;
		}
		else
		{
			instance = new ScriptTemplateBase();
		}

		if (Std.isOfType(childInterp, CustomInterp))
			cast(childInterp, CustomInterp).parentInstance = instance.__superInstance != null ? instance.__superInstance : instance;

		// Wire the child interpreter to the instance
		instance.__interp = childInterp;
		childInterp.variables.set("this", instance);

		// Execute each field/method declaration in the class body.
		// IMPORTANT: EVar declarations must go into `variables` (not `locals`)
		// so they persist across method calls. Locals are ephemeral; each
		// method call restores its own capturedLocals snapshot and would
		// silently shadow the instance field with a stale copy.
		for (fieldExpr in fields)
		{
			switch (crowplexus.hscript.Tools.expr(fieldExpr))
			{
				case EVar(name, _, init):
					// Evaluate the initializer directly on the child interp,
					// then promote to variables so hget/hset can find it.
					var initVal:Dynamic = null;
					if (init != null)
						@:privateAccess initVal = childInterp.expr(init);
					childInterp.variables.set(name, initVal);
				default:
					@:privateAccess childInterp.exprReturn(fieldExpr);
			}
		}

		// Expose super so scripts can call super.method()
		if (instance.__superInstance != null)
		{
			var superValue:Dynamic = instance.__superInstance;
			if (Std.isOfType(superValue, IScriptSuperProxyProvider))
				superValue = cast(superValue, IScriptSuperProxyProvider).getScriptSuperProxy();
			childInterp.variables.set("super", superValue);
		}

		// Run custom constructor if defined
		var ctorFn:Dynamic = childInterp.variables.get("new");
		if (ctorFn != null)
		{
			Reflect.callMethod(null, ctorFn, args);
		}

		return instance;
	}

	public function toString():String
	{
		return 'ScriptClass($name)';
	}
}

// ─────────────────────────────────────────────────────────
// Wrapper object: the actual "this" inside a scripted class.
// All field accesses route through hget/hset so the interpreter
// resolves them from its own variables map.
// ─────────────────────────────────────────────────────────
class ScriptTemplateBase implements IScriptCustomBehaviour
{
	/** The child interpreter that holds all fields/methods for this instance. **/
	public var __interp:Interp;

	/** If the class `extends` a real Haxe class, this holds that instance. **/
	public var __superInstance:Dynamic;

	public function new()
	{
	}

	public function hget(name:String):Dynamic
	{
		if (__interp == null)
			return getPropertySafe(this, name);
		var own:Dynamic = getScriptField(name);
		if (own != null || hasScriptField(name))
			return own;
		// Forward to super instance
		if (__superInstance != null)
			return getPropertySafe(__superInstance, name);
		return getPropertySafe(this, name);
	}

	public function hset(name:String, val:Dynamic):Dynamic
	{
		if (__interp == null)
		{
			Reflect.setProperty(this, name, val);
			return val;
		}
		// Property setter: set_name
		var setter:Dynamic = __interp.variables.get('set_$name');
		if (setter != null && Reflect.isFunction(setter))
		{
			setter(val);
			return val;
		}
		// Existing variable in script
		if (__interp.variables.exists(name))
		{
			__interp.variables.set(name, val);
			return val;
		}
		// Forward to super instance
		if (__superInstance != null)
		{
			setPropertySafe(__superInstance, name, val);
			return val;
		}
		// Otherwise store in script variables
		__interp.variables.set(name, val);
		return val;
	}

	public function hasScriptField(name:String):Bool
		return __interp != null && (__interp.variables.exists(name) || __interp.variables.exists('get_$name'));

	public function getScriptField(name:String):Dynamic
	{
		if (__interp == null)
			return null;
		var getter:Dynamic = __interp.variables.get('get_$name');
		if (getter != null && Reflect.isFunction(getter))
			return getter();
		if (__interp.variables.exists(name))
			return __interp.variables.get(name);
		return null;
	}

	public function setScriptField(name:String, val:Dynamic):Dynamic
	{
		if (__interp == null)
			return val;
		var setter:Dynamic = __interp.variables.get('set_$name');
		if (setter != null && Reflect.isFunction(setter))
		{
			setter(val);
			return val;
		}
		__interp.variables.set(name, val);
		return val;
	}

	static function getPropertySafe(target:Dynamic, name:String):Dynamic
	{
		if (target == null)
			return null;
		try
		{
			var value:Dynamic = Reflect.getProperty(target, name);
			if (value != null)
				return value;
		}
		catch (e:Dynamic)
		{
		}
		try
		{
			return Reflect.field(target, name);
		}
		catch (e:Dynamic)
		{
		}
		return null;
	}

	static function setPropertySafe(target:Dynamic, name:String, value:Dynamic):Void
	{
		if (target == null)
			return;
		try
		{
			Reflect.setProperty(target, name, value);
			return;
		}
		catch (e:Dynamic)
		{
		}
		try
		{
			Reflect.setField(target, name, value);
		}
		catch (e:Dynamic)
		{
		}
	}

	/**
	 * Call a method defined in the script by name.
	 * Useful from Haxe code to invoke overridden lifecycle hooks.
	 */
	public function callMethod(name:String, ?args:Array<Dynamic>):Dynamic
	{
		if (__interp == null)
			return null;
		var fn:Dynamic = __interp.variables.get(name);
		if (fn == null)
			return null;
		if (!Reflect.isFunction(fn))
			return null;
		return Reflect.callMethod(null, fn, args != null ? args : []);
	}

	/**
	 * Returns whether this scripted instance has a method of the given name.
	 */
	public function hasMethod(name:String):Bool
	{
		if (__interp == null)
			return false;
		var v = __interp.variables.get(name);
		return v != null && Reflect.isFunction(v);
	}
}


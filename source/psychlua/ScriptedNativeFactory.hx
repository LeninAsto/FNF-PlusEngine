package psychlua;

#if HSCRIPT_ALLOWED
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.group.FlxSpriteGroup;
import backend.MusicBeatState;
import backend.MusicBeatSubstate;
import psychlua.ScriptedClass.IScriptCustomBehaviour;
import psychlua.ScriptedClass.IScriptSuperProxyProvider;
import psychlua.ScriptedClass.ScriptClassHandler;
import psychlua.ScriptedClass.ScriptTemplateBase;

class ScriptedNativeFactory
{
	public static function create(handler:ScriptClassHandler, superCl:Class<Dynamic>, args:Array<Dynamic>):Dynamic
	{
		if (superCl == FlxSprite)
			return new ScriptedFlxSprite(handler, args);
		if (superCl == FlxSpriteGroup)
			return new ScriptedFlxSpriteGroup(handler, args);
		if (superCl == MusicBeatState)
			return new ScriptedMusicBeatState(handler, args);
		if (superCl == MusicBeatSubstate)
			return new ScriptedMusicBeatSubstate(handler, args);
		if (superCl == FlxState)
			return new ScriptedFlxState(handler, args);
		if (superCl == FlxSubState)
			return new ScriptedFlxSubState(handler, args);
		return null;
	}

	public static function buildOn(handler:ScriptClassHandler, native:Dynamic, args:Array<Dynamic>):ScriptTemplateBase
	{
		var vars = handler.ogInterp.variables;
		var hadNativeSelf:Bool = vars.exists('__scriptedNativeSelf');
		var oldNativeSelf:Dynamic = hadNativeSelf ? vars.get('__scriptedNativeSelf') : null;

		vars.set('__scriptedNativeSelf', native);
		var created:Dynamic = handler.hnew(args);
		if (hadNativeSelf)
			vars.set('__scriptedNativeSelf', oldNativeSelf);
		else
			vars.remove('__scriptedNativeSelf');

		return Std.isOfType(created, ScriptTemplateBase) ? cast created : null;
	}

	public static function call(instance:ScriptTemplateBase, name:String, ?args:Array<Dynamic>):Dynamic
	{
		if (instance == null || !instance.hasMethod(name))
			return null;

		try
		{
			return instance.callMethod(name, args);
		}
		catch (e:Dynamic)
		{
			trace('[ScriptedNative] $name failed: $e');
			return null;
		}
	}

	public static function has(instance:ScriptTemplateBase, name:String):Bool
		return instance != null && instance.hasMethod(name);

	public static function numberArg(args:Array<Dynamic>, index:Int, fallback:Float):Float
	{
		if (args == null || index >= args.length || args[index] == null)
			return fallback;
		return Std.parseFloat(Std.string(args[index]));
	}

	public static function stringArg(args:Array<Dynamic>, index:Int):String
	{
		if (args == null || index >= args.length || args[index] == null)
			return null;
		return Std.string(args[index]);
	}

	public static function makeSuperFunction(native:Dynamic, ctor:Array<Dynamic>->Dynamic, methods:Map<String, Dynamic>):Dynamic
	{
		var fn:Dynamic = Reflect.makeVarArgs(ctor);
		for (name => method in methods)
			Reflect.setField(fn, name, method);
		Reflect.setField(fn, 'native', native);
		return fn;
	}

	public static function getScriptAware(native:Dynamic, scriptInstance:ScriptTemplateBase, name:String):Dynamic
	{
		var nativeValue:Dynamic = getNative(native, name);
		if (nativeValue != null)
			return nativeValue;

		if (scriptInstance != null && scriptInstance.hasScriptField(name))
			return scriptInstance.getScriptField(name);

		return null;
	}

	public static function setScriptAware(native:Dynamic, scriptInstance:ScriptTemplateBase, name:String, value:Dynamic):Dynamic
	{
		if (scriptInstance != null && scriptInstance.hasScriptField(name))
			return scriptInstance.setScriptField(name, value);

		setNative(native, name, value);
		return value;
	}

	static function getNative(native:Dynamic, name:String):Dynamic
	{
		if (native == null)
			return null;
		try
		{
			var value:Dynamic = Reflect.getProperty(native, name);
			if (value != null)
				return value;
		}
		catch (e:Dynamic)
		{
		}
		try
		{
			return Reflect.field(native, name);
		}
		catch (e:Dynamic)
		{
		}
		return null;
	}

	static function setNative(native:Dynamic, name:String, value:Dynamic):Void
	{
		if (native == null)
			return;
		try
		{
			Reflect.setProperty(native, name, value);
			return;
		}
		catch (e:Dynamic)
		{
		}
		try
		{
			Reflect.setField(native, name, value);
		}
		catch (e:Dynamic)
		{
		}
	}
}

class ScriptedFlxState extends FlxState implements IScriptSuperProxyProvider implements IScriptCustomBehaviour
{
	var scriptInstance:ScriptTemplateBase;
	var superProxy:Dynamic;

	public function new(handler:ScriptClassHandler, args:Array<Dynamic>)
	{
		super();
		scriptInstance = ScriptedNativeFactory.buildOn(handler, this, args);
	}

	public function getScriptSuperProxy():Dynamic
	{
		if (superProxy == null)
		{
			var methods:Map<String, Dynamic> = [];
			methods.set('create', nativeSuperCreate);
			methods.set('update', nativeSuperUpdate);
			methods.set('destroy', nativeSuperDestroy);
			superProxy = ScriptedNativeFactory.makeSuperFunction(this, nativeSuperNew, methods);
		}
		return superProxy;
	}

	public function hget(name:String):Dynamic
		return ScriptedNativeFactory.getScriptAware(this, scriptInstance, name);

	public function hset(name:String, val:Dynamic):Dynamic
		return ScriptedNativeFactory.setScriptAware(this, scriptInstance, name, val);

	function nativeSuperNew(args:Array<Dynamic>):Dynamic
		return this;

	function nativeSuperCreate():Void
		super.create();

	function nativeSuperUpdate(elapsed:Float):Void
		super.update(elapsed);

	function nativeSuperDestroy():Void
		super.destroy();

	override function create():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'create'))
			ScriptedNativeFactory.call(scriptInstance, 'create');
		else
			super.create();
	}

	override function update(elapsed:Float):Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'update'))
			ScriptedNativeFactory.call(scriptInstance, 'update', [elapsed]);
		else
			super.update(elapsed);
	}

	override function destroy():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'destroy'))
			ScriptedNativeFactory.call(scriptInstance, 'destroy');
		else
			super.destroy();
		scriptInstance = null;
		superProxy = null;
	}
}

class ScriptedFlxSubState extends FlxSubState implements IScriptSuperProxyProvider implements IScriptCustomBehaviour
{
	var scriptInstance:ScriptTemplateBase;
	var superProxy:Dynamic;

	public function new(handler:ScriptClassHandler, args:Array<Dynamic>)
	{
		super();
		scriptInstance = ScriptedNativeFactory.buildOn(handler, this, args);
	}

	public function getScriptSuperProxy():Dynamic
	{
		if (superProxy == null)
		{
			var methods:Map<String, Dynamic> = [];
			methods.set('create', nativeSuperCreate);
			methods.set('update', nativeSuperUpdate);
			methods.set('close', nativeSuperClose);
			methods.set('destroy', nativeSuperDestroy);
			superProxy = ScriptedNativeFactory.makeSuperFunction(this, nativeSuperNew, methods);
		}
		return superProxy;
	}

	public function hget(name:String):Dynamic
		return ScriptedNativeFactory.getScriptAware(this, scriptInstance, name);

	public function hset(name:String, val:Dynamic):Dynamic
		return ScriptedNativeFactory.setScriptAware(this, scriptInstance, name, val);

	function nativeSuperNew(args:Array<Dynamic>):Dynamic
		return this;

	function nativeSuperCreate():Void
		super.create();

	function nativeSuperUpdate(elapsed:Float):Void
		super.update(elapsed);

	function nativeSuperClose():Void
		super.close();

	function nativeSuperDestroy():Void
		super.destroy();

	override function create():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'create'))
			ScriptedNativeFactory.call(scriptInstance, 'create');
		else
			super.create();
	}

	override function update(elapsed:Float):Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'update'))
			ScriptedNativeFactory.call(scriptInstance, 'update', [elapsed]);
		else
			super.update(elapsed);
	}

	override function close():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'close'))
			ScriptedNativeFactory.call(scriptInstance, 'close');
		else
			super.close();
	}

	override function destroy():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'destroy'))
			ScriptedNativeFactory.call(scriptInstance, 'destroy');
		else
			super.destroy();
		scriptInstance = null;
		superProxy = null;
	}
}

class ScriptedMusicBeatState extends MusicBeatState implements IScriptSuperProxyProvider implements IScriptCustomBehaviour
{
	var scriptInstance:ScriptTemplateBase;
	var superProxy:Dynamic;

	public function new(handler:ScriptClassHandler, args:Array<Dynamic>)
	{
		super(false);
		scriptInstance = ScriptedNativeFactory.buildOn(handler, this, args);
	}

	public function getScriptSuperProxy():Dynamic
	{
		if (superProxy == null)
		{
			var methods:Map<String, Dynamic> = [];
			methods.set('create', nativeSuperCreate);
			methods.set('update', nativeSuperUpdate);
			methods.set('stepHit', nativeSuperStepHit);
			methods.set('beatHit', nativeSuperBeatHit);
			methods.set('sectionHit', nativeSuperSectionHit);
			methods.set('destroy', nativeSuperDestroy);
			superProxy = ScriptedNativeFactory.makeSuperFunction(this, nativeSuperNew, methods);
		}
		return superProxy;
	}

	public function hget(name:String):Dynamic
		return ScriptedNativeFactory.getScriptAware(this, scriptInstance, name);

	public function hset(name:String, val:Dynamic):Dynamic
		return ScriptedNativeFactory.setScriptAware(this, scriptInstance, name, val);

	function nativeSuperNew(args:Array<Dynamic>):Dynamic
		return this;

	function nativeSuperCreate():Void
		super.create();

	function nativeSuperUpdate(elapsed:Float):Void
		super.update(elapsed);

	function nativeSuperStepHit():Void
		super.stepHit();

	function nativeSuperBeatHit():Void
		super.beatHit();

	function nativeSuperSectionHit():Void
		super.sectionHit();

	function nativeSuperDestroy():Void
		super.destroy();

	override function create():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'create'))
			ScriptedNativeFactory.call(scriptInstance, 'create');
		else
			super.create();
	}

	override function update(elapsed:Float):Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'update'))
			ScriptedNativeFactory.call(scriptInstance, 'update', [elapsed]);
		else
			super.update(elapsed);
	}

	override public function stepHit():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'stepHit'))
			ScriptedNativeFactory.call(scriptInstance, 'stepHit');
		else
			super.stepHit();
	}

	override public function beatHit():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'beatHit'))
			ScriptedNativeFactory.call(scriptInstance, 'beatHit');
		else
			super.beatHit();
	}

	override public function sectionHit():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'sectionHit'))
			ScriptedNativeFactory.call(scriptInstance, 'sectionHit');
		else
			super.sectionHit();
	}

	override function destroy():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'destroy'))
			ScriptedNativeFactory.call(scriptInstance, 'destroy');
		else
			super.destroy();
		scriptInstance = null;
		superProxy = null;
	}
}

class ScriptedMusicBeatSubstate extends MusicBeatSubstate implements IScriptSuperProxyProvider implements IScriptCustomBehaviour
{
	var scriptInstance:ScriptTemplateBase;
	var superProxy:Dynamic;

	public function new(handler:ScriptClassHandler, args:Array<Dynamic>)
	{
		super();
		scriptInstance = ScriptedNativeFactory.buildOn(handler, this, args);
	}

	public function getScriptSuperProxy():Dynamic
	{
		if (superProxy == null)
		{
			var methods:Map<String, Dynamic> = [];
			methods.set('create', nativeSuperCreate);
			methods.set('update', nativeSuperUpdate);
			methods.set('stepHit', nativeSuperStepHit);
			methods.set('beatHit', nativeSuperBeatHit);
			methods.set('sectionHit', nativeSuperSectionHit);
			methods.set('close', nativeSuperClose);
			methods.set('destroy', nativeSuperDestroy);
			superProxy = ScriptedNativeFactory.makeSuperFunction(this, nativeSuperNew, methods);
		}
		return superProxy;
	}

	public function hget(name:String):Dynamic
		return ScriptedNativeFactory.getScriptAware(this, scriptInstance, name);

	public function hset(name:String, val:Dynamic):Dynamic
		return ScriptedNativeFactory.setScriptAware(this, scriptInstance, name, val);

	function nativeSuperNew(args:Array<Dynamic>):Dynamic
		return this;

	function nativeSuperCreate():Void
		super.create();

	function nativeSuperUpdate(elapsed:Float):Void
		super.update(elapsed);

	function nativeSuperStepHit():Void
		super.stepHit();

	function nativeSuperBeatHit():Void
		super.beatHit();

	function nativeSuperSectionHit():Void
		super.sectionHit();

	function nativeSuperClose():Void
		super.close();

	function nativeSuperDestroy():Void
		super.destroy();

	override function create():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'create'))
			ScriptedNativeFactory.call(scriptInstance, 'create');
		else
			super.create();
	}

	override function update(elapsed:Float):Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'update'))
			ScriptedNativeFactory.call(scriptInstance, 'update', [elapsed]);
		else
			super.update(elapsed);
	}

	override public function stepHit():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'stepHit'))
			ScriptedNativeFactory.call(scriptInstance, 'stepHit');
		else
			super.stepHit();
	}

	override public function beatHit():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'beatHit'))
			ScriptedNativeFactory.call(scriptInstance, 'beatHit');
		else
			super.beatHit();
	}

	override public function sectionHit():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'sectionHit'))
			ScriptedNativeFactory.call(scriptInstance, 'sectionHit');
		else
			super.sectionHit();
	}

	override function close():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'close'))
			ScriptedNativeFactory.call(scriptInstance, 'close');
		else
			super.close();
	}

	override function destroy():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'destroy'))
			ScriptedNativeFactory.call(scriptInstance, 'destroy');
		else
			super.destroy();
		scriptInstance = null;
		superProxy = null;
	}
}

class ScriptedFlxSprite extends FlxSprite implements IScriptSuperProxyProvider implements IScriptCustomBehaviour
{
	var scriptInstance:ScriptTemplateBase;
	var superProxy:Dynamic;

	public function new(handler:ScriptClassHandler, args:Array<Dynamic>)
	{
		super(ScriptedNativeFactory.numberArg(args, 0, 0), ScriptedNativeFactory.numberArg(args, 1, 0), ScriptedNativeFactory.stringArg(args, 2));
		scriptInstance = ScriptedNativeFactory.buildOn(handler, this, args);
	}

	public function getScriptSuperProxy():Dynamic
	{
		if (superProxy == null)
		{
			var methods:Map<String, Dynamic> = [];
			methods.set('update', nativeSuperUpdate);
			methods.set('destroy', nativeSuperDestroy);
			superProxy = ScriptedNativeFactory.makeSuperFunction(this, nativeSuperNew, methods);
		}
		return superProxy;
	}

	public function hget(name:String):Dynamic
		return ScriptedNativeFactory.getScriptAware(this, scriptInstance, name);

	public function hset(name:String, val:Dynamic):Dynamic
		return ScriptedNativeFactory.setScriptAware(this, scriptInstance, name, val);

	function nativeSuperNew(args:Array<Dynamic>):Dynamic
	{
		x = ScriptedNativeFactory.numberArg(args, 0, x);
		y = ScriptedNativeFactory.numberArg(args, 1, y);
		var graphic:String = ScriptedNativeFactory.stringArg(args, 2);
		if (graphic != null)
			loadGraphic(graphic);
		return this;
	}

	function nativeSuperUpdate(elapsed:Float):Void
		super.update(elapsed);

	function nativeSuperDestroy():Void
		super.destroy();

	override public function update(elapsed:Float):Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'update'))
			ScriptedNativeFactory.call(scriptInstance, 'update', [elapsed]);
		else
			super.update(elapsed);
	}

	override public function destroy():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'destroy'))
			ScriptedNativeFactory.call(scriptInstance, 'destroy');
		else
			super.destroy();
		scriptInstance = null;
		superProxy = null;
	}
}

class ScriptedFlxSpriteGroup extends FlxSpriteGroup implements IScriptSuperProxyProvider implements IScriptCustomBehaviour
{
	var scriptInstance:ScriptTemplateBase;
	var superProxy:Dynamic;

	public function new(handler:ScriptClassHandler, args:Array<Dynamic>)
	{
		super(ScriptedNativeFactory.numberArg(args, 0, 0), ScriptedNativeFactory.numberArg(args, 1, 0));
		scriptInstance = ScriptedNativeFactory.buildOn(handler, this, args);
	}

	public function getScriptSuperProxy():Dynamic
	{
		if (superProxy == null)
		{
			var methods:Map<String, Dynamic> = [];
			methods.set('update', nativeSuperUpdate);
			methods.set('destroy', nativeSuperDestroy);
			superProxy = ScriptedNativeFactory.makeSuperFunction(this, nativeSuperNew, methods);
		}
		return superProxy;
	}

	public function hget(name:String):Dynamic
		return ScriptedNativeFactory.getScriptAware(this, scriptInstance, name);

	public function hset(name:String, val:Dynamic):Dynamic
		return ScriptedNativeFactory.setScriptAware(this, scriptInstance, name, val);

	function nativeSuperNew(args:Array<Dynamic>):Dynamic
	{
		x = ScriptedNativeFactory.numberArg(args, 0, x);
		y = ScriptedNativeFactory.numberArg(args, 1, y);
		return this;
	}

	function nativeSuperUpdate(elapsed:Float):Void
		super.update(elapsed);

	function nativeSuperDestroy():Void
		super.destroy();

	override public function update(elapsed:Float):Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'update'))
			ScriptedNativeFactory.call(scriptInstance, 'update', [elapsed]);
		else
			super.update(elapsed);
	}

	override public function destroy():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'destroy'))
			ScriptedNativeFactory.call(scriptInstance, 'destroy');
		else
			super.destroy();
		scriptInstance = null;
		superProxy = null;
	}
}
#end
